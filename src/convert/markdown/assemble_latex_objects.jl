"""
$SIGNATURES

After the partitioning, latex objects are not quite formed; they need to be merged into
larger objects including the relevant braces.
The function gradually goes over the blocks, adds new latex definitions to the context
and assembles latex commands and environments based on existing definitions.
"""
function assemble_latex_objects!(parts::Vector{Block}, ctx::Context)
    index_to_remove = Int[]
    i = 1
    @inbounds while i <= lastindex(parts)
        part = parts[i]
        n = 0
        if part.name in (:LX_NEWCOMMAND, :LX_NEWENVIRONMENT)
            parts[i], n = try_form_lxdef(part, i, parts, ctx)
        elseif part.name == :LX_COMMAND
            parts[i], n = try_form_lxcom(i, parts, ctx)
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
    m = """
        $m
        Franklin saw: '$(b.ss)'.
        """
    FRANKLIN_ENV[:STRICT_PARSING] && throw(m)
    FRANKLIN_ENV[:SHOW_WARNINGS]  && @warn m
    # form a "failedblock"
    return Block(:FAILED_BLOCK, b.ss)
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
    # \newcommand{\naming}[narg]{def}
    # \newenvironment{naming}[narg]{pre}{post}
    case = ifelse(part.name == :LX_NEWCOMMAND, :com, :env)
    # find all brace blocks
    braces_idx = findall(p -> p.name == :LXB, @view parts[i+1:end])

    # CHECK if there are enough braces
    if length(braces_idx) < 2 || (case == :env && length(braces_idx) < 3)
        m = """
            Not enough braces found after a \\newcommand or \\newenvironment.
            """
        return failed_block(part, m), 0
    end
    naming_idx = i + braces_idx[1]
    naming = parts[naming_idx]

    # CHECK if the naming brace properly located
    if to(part) + 1 != from(naming)
        m = """
            The naming brace of a \\newcommand or \\newenvironment was badly located.
            It should be immediately after the \\new***. For instance,
            \\newcommand{\\foo}{...} is ok but not \\newcommand {\\foo}{...}.
            """
        return failed_block(part, m), 0
    end

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
        m = match(PAT_LX_NARGS, c)
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
    def = dedent(content(nextb))

    # found a newcommand! push it to context and return a skipped block
    if case == :com
        push!(ctx.lxdefs, LxDef(
            string(strip(content(naming), '\\')),
            nargs,          # number of arguments
            def,            # the definition
            from(part),     # location
            to(nextb)))
        return Block(:COMMENT, subs("")), 2 + Int(nargs_block)
    end

    # if env, get one extra brace which also must be a brace
    pre = def
    nextb = parts[next_idx+1]
    if nextb.name != :LXB
        return failed_block(part, next_bad), 0
    end
    post = dedent(content(nextb))

    # found a newenvironment! push it to context and return a skipped block
    push!(ctx.lxdefs, LxDef(
        strip(naming, '\\'),    # name
        nargs,                  # number of arguments
        pre => post,            # the definition
        from(part),             # location
        to(nextb)))
    return Block(:COMMENT, subs("")), 3 + Int(nargs_block)
end

"""
fii
"""
function try_form_lxcom(parts::Vector{Block}, ctx::Context, i::Int)
    return
end

function try_form_lxenv(parts::Vector{Block}, ctx::Context, i::Int)
    return
end
