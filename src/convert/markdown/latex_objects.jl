"""
    process_latex_objects!(parts::Vector{Block}, ctx::LocalContext)

After the partitioning, latex objects are not quite formed; in particular they
are not yet associated with the relevant braces.
This function gradually goes over the blocks, adds new latex definitions to
the context and assembles latex commands and environments based on existing
definitions.

The normal process is:
  * newcom/env: addition to context, replace by comment block (invisible).
  * com/env: read from context, form intermediate text, recurse and replace
             by a raw block.

If things fail, either a "failed block" is returned (shows up as read, doesn't
stop the procedure) or an error is thrown (if strict parsing is on).
"""
function process_latex_objects!(
            parts::Vector{Block},
            ctx::Context;
            recursion::Function=html
            )::Nothing

    index_to_remove = Int[]
    i = 1
    @inbounds while i <= lastindex(parts)
        part = parts[i]
        n = 0
        if part.name in (:LX_NEWCOMMAND, :LX_NEWENVIRONMENT)
            parts[i], n = try_form_lxdef(part, i, parts, ctx)
        elseif part.name == :LX_COMMAND
            parts[i], n = try_resolve_lxcom(i, parts, ctx; recursion=recursion)
        elseif part.name == :LXB
            # stray braces
            parts[i], n = raw_inline_block(part), 0
        elseif part.name == :LX_BEGIN
            parts[i], n = try_resolve_lxenv(i, parts, ctx; recursion=recursion)
        elseif part.name == :LX_END
            if ctx.is_math[]
                parts[i], n = raw_inline_block(part), 0
            else
                m = "Found an orphaned \\end."
                parts[i], n = failed_block(part, m), 0
            end
        end
        append!(index_to_remove, i+1:i+n)
        i += n + 1
    end
    # remove the blocks that have been merged
    deleteat!(parts, index_to_remove)
    return
end


"""
    failed_block(b::Block, m::String)

In the case of an issue, e.g. a command with not enough braces, either an error
is thrown (if strict parsing is on) or a warning along with a "failed block"
which will make the object appear in red on the document without crashing the
server.
"""
function failed_block(
            b::Block,
            m::String
            )::Block

    env(:strict_parsing) && throw(m)
    env(:show_warnings)  && @warn m
    # form a "failedblock"
    return Block(:FAILED, b.ss)
end


"""
    try_form_lxdef(...)

Given an indicator of a newcommand or a newenvironment, try to find the
relevant braces and, if successful, add the definition to the context.
If unsuccessful, return a failed block.

Note the proper syntax for newcommand and newenvironment are respectively:
  * `\\newcommand{\\naming}[narg]{def}`
  * `\\newenvironment{naming}[narg]{pre}{post}`
"""
function try_form_lxdef(
            part::Block,
            i::Int,
            parts::Vector{Block},
            ctx::LocalContext
            )::Tuple{Block,Int}

    # command or env?
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
        The block(s) following the naming brace of a \\newcommand or
        \\newenvironment is/are incorrect, Franklin expected another brace or
        a text indicating the number of arguments followed by defining
        brace(s).
        For environments, the defining braces should not be separated (i.e.
        the closing brace and the following opening brace should touch).
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
        name = lstrip(strip(content(naming)), '\\') |> string
        setdef!(ctx, name, LxDef(nargs, def, from(part), to(nextb)))
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
    name = strip(content(naming)) |> string
    setdef!(ctx, name, LxDef(nargs, pre => post, from(part), to(nextb)))
    return Block(:COMMENT, subs("")), 3 + Int(nargs_block)
end


"""
    try_resolve_lxcom(...)

When seeing an indicator of a command, try to resolve it with the appropriate definition
from the context. If there's no definition, either fail or leave as is if we're in maths
mode (in which case it might be something for the math engine to handle).
"""
function try_resolve_lxcom(
            i::Int,
            parts::Vector{Block},
            ctx::LocalContext;
            recursion::Function=html
            )::Tuple{Block,Int}
    # Process:
    # 1. look for definition --> fail if none and not in math mode
    # 2. extract nargs and take the next nargs blocks --> fail if not enough
    #      and if not all braces
    # 3. assemble into string and resolve via html(...)
    # 4. if there's only a single set of `<p>...</p>`, remove it, otherwise
    #      leave stuff as they are (with a potential risk of nested <p></p>
    #      but they should at least remain balanced...
    # ------------------------------------------------------------------------
    # 1 -- look for definition
    cand = parts[i]
    name = lstrip(cand.ss, '\\') |> string
    if !hasdef(ctx, name)
        if ctx.is_math[]
            return raw_inline_block(cand), 0
        end
        m = "Command '$(cand.ss)' used before it was defined."
        return failed_block(cand, m), 0
    end
    lxdef = getdef(ctx, name)

    # runtime check; lxdef should be a LxDef{String} otherwise
    # there's a clash in names with an environment
    if lxdef isa LxDef{Pair{String,String}}
        m = """
            There is a clashing definition of an environment with name '$name'.
            This is not allowed; use unique names for environments and commands.
            """
        return failed_block(cand, m), 0
    end

    # 2 -- get nargs
    nargs = lxdef.nargs
    if (i + nargs > lastindex(parts)) || any(e -> e.name != :LXB, @view parts[i+1:i+nargs])
        m = "Not enough braces to resolve '$(cand.ss)'."
        return failed_block(cand, m), 0
    end

    # 3 -- assemble into string and process
    r = lxdef.def::String
    # in math env, inject whitespace to avoid issues with chains; this can't happen
    # outside of maths envs as we force the use of braces
    p = ifelse(ctx.is_math[], " ", "")
    @inbounds for k in 1:nargs
        c = content(parts[i+k])
        r = replace(r, "!#$k" => c)
        r = replace(r, "#$k"  => p * c)
    end
    r2 = recursion(r, recursify(ctx))

    # 4 -- in latex case, strip \\par
    if recursion === latex
        r3 = ifelse(endswith(r2, "\\par\n"),
                chop(r2, head=0, tail=5),
                subs(r2)
             )
        return Block(:RAW_INLINE, r3), nargs
    end

    # 4 -- try to match with exactly one <p>...</p>
    default = (Block(:RAW_INLINE, subs(r2)), nargs)
    m = match(r"^<p>(.*?)<\/p>\s*$", r2)
    m === nothing && return default
    c = m.captures[1]
    if length(collect(eachmatch(r"<p>", c))) > 0
        return default
    end
    # otherwise return "content" (so that properly merged)
    return Block(:RAW_INLINE, subs(c)), nargs
end


"""
    try_resolve_lxenv(...)

Same process as for a command except we need to find the matching `\\end` block.
"""
function try_resolve_lxenv(
            i::Int,
            parts::Vector{Block},
            ctx::LocalContext;
            recursion::Function=html
            )::Tuple{Block,Int}
    # Process:
    # 0. find the matching closing \end{...}
    # 1-3 as for try_resolve_lxcom (no finalize, env is a block)
    # ------------------------------------------------------------------------
    cand = parts[i]
    m = "Not enough braces and elements after a \\begin for it to be valid."
    i == lastindex(parts) && return failed_block(cand, m), 0
    naming_brace = parts[i+1]
    if naming_brace.name != :LXB
        m = """
            Expected a brace immediately after a \\begin with the name of the
            environment.
            """
        return failed_block(cand, m), 0
    end
    env_name = strip(content(naming_brace)) |> string

    imbalance = 1
    k = i + 1
    @inbounds while (imbalance > 0) && (k < lastindex(parts))
        if parts[k].name == :LX_END &&
             parts[k+1].name == :LXB  &&
               strip(content(parts[k+1])) == env_name
           imbalance -= 1
        end
        k += 1
    end
    if imbalance > 0
        m = "Couldn't close a \\begin{$env_name} with a valid \\end{$env_name}."
        return failed_block(parts, m), 0
    end

    # 1 -- look for definition
    if !hasdef(ctx, env_name)
        if ctx.is_math[]
            return raw_inline_block(cand), 0
        end
        m = "Environment '$env_name' used before it was defined."
        return failed_block(cand, m), 0
    end
    lxdef = getdef(ctx, env_name)

    # runtime check; lxdef should be a LxDef{Pair{String,String}} otherwise
    # there's a clash in names with an environment
    if lxdef isa LxDef{String}
        m = """
            There is a clashing definition of a command with name '$name'.
            This is not allowed; use unique names for environments and commands.
            """
        return failed_block(cand, m), 0
    end

    # 2 -- get nargs
    nargs = lxdef.nargs
    if (i+1+nargs > lastindex(parts)) || any(e -> e.name != :LXB, @view parts[i+2:i+1+nargs])
        m = "Not enough braces to resolve environment '$env_name'."
        return failed_block(cand, m), 0
    end

    # 3 -- assemble into string and process
    def  = lxdef.def::Pair{String,String}
    pre  = def.first
    post = def.second

    s = parent_string(cand)
    env_content = subs(s, next_index(parts[i+1+nargs]), previous_index(parts[k-1]))
    env_content = strip(dedent(env_content))

    @inbounds for j in 1:nargs
        c    = content(parts[i+1+j])
        pre  = replace(pre,  "#$j" => c)
        post = replace(post, "#$j" => c)
    end
    r2 = recursion(pre * env_content * post, recursify(ctx))

    # 4 -- finalize
    default = Block(:RAW_BLOCK, subs(r2)), k - i
    m = match(r"^<p>(.*?)<\/p>\s*$", r2)
    m === nothing && return default
    c = m.captures[1]
    if length(collect(eachmatch(r"<p>", c))) > 0
        return default
    end
    # otherwise return "content" (so that properly merged)
    return Block(:RAW_BLOCK, subs(c)), k - i
end
