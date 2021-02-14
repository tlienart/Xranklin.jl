"""
    process_latex_objects!(parts::Vector{Block}, ctx::Context)

After the partitioning, latex objects are not quite formed; in particular they are not
yet considered with the relevant braces.
This function gradually goes over the blocks, adds new latex definitions to the context
and assembles latex commands and environments based on existing definitions.

The normal process is:
  * newcommand/environment: addition to context, replace by a comment block (invisible).
  * command/environment: read from context, form intermediate text, recurse and replace
        by a raw block.

If things fail, either a "failed block" is returned (shows up as read, doesn't stop the
procedure) or an error is thrown (if strict parsing is on).
"""
function process_latex_objects!(parts::Vector{Block}, ctx::Context)
    index_to_remove = Int[]
    i = 1
    @inbounds while i <= lastindex(parts)
        part = parts[i]
        n = 0
        if part.name in (:LX_NEWCOMMAND, :LX_NEWENVIRONMENT)
            parts[i], n = try_form_lxdef(part, i, parts, ctx)
        elseif part.name == :LX_COMMAND
            parts[i], n = try_resolve_lxcom(i, parts, ctx)
        elseif part.name == :LX_BEGIN
            parts[i], n = try_form_lxenv(i, parts, ctx)
        end
        append!(index_to_remove, i+1:i+n)
        i += n + 1
    end
    # remove the blocks that have been merged
    deleteat!(parts, index_to_remove)
    return
end


function failed_block(b::Block, m::String)
    FRANKLIN_ENV[:STRICT_PARSING] && throw(m)
    FRANKLIN_ENV[:SHOW_WARNINGS]  && @warn m
    # form a "failedblock"
    return Block(:FAILED, b.ss)
end


"""

Return:
-------
1. a skippable block or failed block
2. a number of blocks to take with it
"""
function try_form_lxdef(
            part::Block,
            i::Int,
            parts::Vector{Block},
            ctx::Context
            )::Tuple{Block,Int}
    #
    # \newcommand{\naming}[narg]{def}
    # \newenvironment{naming}[narg]{pre}{post}
    #
    case = ifelse(part.name == :LX_NEWCOMMAND, :com, :env)
    # find all brace blocks
    braces_idx = findall(p -> p.name == :LXB, @view parts[i+1:end])

    # --------------------------------
    # CHECK if there are enough braces
    if length(braces_idx) < 2 || (case == :env && length(braces_idx) < 3)
        m = """
            Not enough braces found after a \\newcommand or \\newenvironment.
            """
        return failed_block(part, m), 0
    end
    naming_idx = i + braces_idx[1]
    naming = parts[naming_idx]

    # ----------------------------
    # CHECK the following brace(s)
    next_idx = naming_idx + 1
    next_bad = """
        The block(s) following the naming brace of a \\newcommand or \\newenvironment
        is/are incorrect, Franklin expected another brace or a text indicating the
        number of arguments followed by defining brace(s). For environments, the
        defining braces should not be separated (i.e. the closing brace and the
        following opening brace should touch).
        """

    # the next block should either be a brace or a text block with content [.\d.]
    # first we check if its a Text block and if it's a text block we try to parse
    # it or we fail.
    nargs_block = false
    nargs = 0
    if parts[naming_idx + 1].name == :TEXT
        # try parse it as [ . d . ]
        c = content(parts[naming_idx + 1])
        m = match(LX_NARGS_PAT, c)
        m === nothing && return failed_block(part, next_bad), 0
        nargs = parse(Int, m.captures[1])
        nargs_block = true
        next_idx += 1
    end

    # Now the next brace must be a brace otherwise fail
    nextb = parts[next_idx]
    if nextb.name != :LXB
        return failed_block(part, next_bad), 0
    end
    def = content(nextb) |> dedent |> strip |> String

    # found a newcommand! push it to context and return a skipped block
    if case == :com
        name = string(strip(strip(content(naming)), '\\'))
        ctx.lxdefs[name] = LxDef(nargs, def, from(part), to(nextb))
        return Block(:COMMENT, subs("")), 2 + Int(nargs_block)
    end

    # if env, get one extra brace which also must be a brace
    pre = def
    nextb = parts[next_idx+1]
    if nextb.name != :LXB
        return failed_block(part, next_bad), 0
    end
    post = content(nextb) |> dedent |> strip |> String

    # found a newenvironment! push it to context and return a skipped block
    name = string(strip(content(naming)))
    ctx.lxdefs[name] = LxDef(nargs, pre => post, from(part), to(nextb))
    return Block(:COMMENT, subs("")), 3 + Int(nargs_block)
end


"""
fii
"""
function try_resolve_lxcom(
            i::Int,
            parts::Vector{Block},
            ctx::Context
            )::Tuple{Block,Int}
    # 1. look for definition --> fail if none and not in math mode
    # 2. extract nargs
    # 3. take the next nargs blocks --> fail if not that many and if not
    #                                   braces
    # 4. assemble into string
    # 5. resolve via html(...)
    # 6. if there's only a single set of `<p>...</p>`, remove it, otherwise
    #    leave stuff as they are (with a potential risk of nested <p></p> but
    #    they should at least remain balanced...
    # ------------------------------------------------------------------------
    # 1 -- look for definition
    cand = parts[i]
    name = strip(cand.ss, '\\')
    if name ∉ keys(ctx.lxdefs)
        if ctx.is_maths
            return raw_block(cand), 0
        end
        m = "Command '$(cand.ss)' used before it was defined."
        return failed_block(cand, m), 0
    end
    lxdef = ctx.lxdefs[name]::LxDef{String}
    nargs = lxdef.nargs

    # 2+3 -- get nargs
    if (i + nargs > lastindex(parts)) || any(e -> e.name != :LXB, @view parts[i+1:i+nargs])
        m = "Not enough braces to resolve '$(cand.ss)'."
        return failed_block(cand, m), 0
    end

    # 4. assemble into string
    r = lxdef.def
    # in math env, inject whitespace to avoid issues with chains; this can't happen
    # outside of maths envs as we force the use of braces
    p = ifelse(ctx.is_maths, " ", "")
    @inbounds for k in 1:nargs
        c = content(parts[i + k])
        r = replace(r, "!#$k" => c)
        r = replace(r, "#$k"  => p * c)
    end

    # 5 -- form html
    r_html = html(r, recursive(ctx))

    # 6 -- try to match with exactly one <p>...</p>
    default = (Block(:RAW, subs(r_html)), nargs)
    m = match(r"^<p>(.*?)<\/p>\s*$", r_html)
    m === nothing && return default
    c = m.captures[1]
    if length(collect(eachmatch(r"<p>", c))) > 0
        return default
    end
    # otherwise return "content" (so that properly merged)
    return Block(:RAW, subs(c)), nargs
end


"""
fii
"""
function try_resolve_lxenv(parts::Vector{Block}, ctx::Context, i::Int)
    return
end
