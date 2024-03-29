"""
    process_latex_objects!(blocks::Vector{Block}, ctx::LocalContext)

After the partitioning, latex objects are not quite formed; in particular they
are not yet associated with the relevant braces.
This function gradually goes over the blocks, adds new latex definitions to
the context and assembles latex commands and environments based on existing
definitions.

The normal process is:
  * newcom/env: addition to context, replace by comment block (invisible).
  * com:        read from context, form intermediate text, recurse and replace
                 by a raw block.

Environments are processed separately as they don't appear in the same group.

If things fail, either a "failed block" is returned (shows up as read, doesn't
stop the procedure) or an error is thrown (if strict parsing is on).
"""
function process_latex_objects!(
            blocks::Vector{Block},
            ctx::Context;
            tohtml::Bool=true
        )::Nothing

    index_to_remove = Int[]
    i = 1
    @inbounds while i <= lastindex(blocks)
        block = blocks[i]
        n = 0
        if block.name in (:LX_NEWCOMMAND, :LX_NEWENVIRONMENT)
            blocks[i], n = try_form_lxdef(block, i, blocks, ctx)
        elseif block.name == :LX_COMMAND
            blocks[i], n = try_resolve_lxcom(i, blocks, ctx; tohtml)
        elseif startswith(string(block.name), "ENV_")
            blocks[i], n = try_resolve_lxenv([block], ctx; tohtml), 0
        end
        append!(index_to_remove, i+1:i+n)
        i += n + 1
    end
    # remove the blocks that have been merged
    deleteat!(blocks, index_to_remove)
    return
end


"""
    failed_block(c::Context, bs::Vector{Block}, m::String)

In the case of an issue, e.g. a command with not enough braces, either an error
is thrown (if strict parsing is on) or a warning along with a "failed block"
which will make the object appear in red on the document without crashing the
server.
"""
function failed_block(
            c::Context,
            bs::Vector{Block},
            m::String
        )::Block
    isa(c, LocalContext) && setvar!(c, :_has_failed_blocks, true)
    env(:strict_parsing) && throw(m)
    @warn m
    s = parent_string(bs[1].ss)
    return Block(:FAILED, subs(s, from(bs[1]), to(bs[end])))
end
failed_block(c, b::Block, m) = failed_block(c, [b], m)


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
            block::Block,
            i::Int,
            blocks::Vector{Block},
            ctx::Context
        )::Tuple{Block,Int}

    crumbs(@fname, str_fmt(block.ss, 30))

    n_blocks = length(blocks)
    # command or env?
    case = ifelse(block.name == :LX_NEWCOMMAND, :com, :env)
    # find all brace blocks
    braces_idx = findall(p -> p.name == :CU_BRACKETS, @view blocks[i+1:end])
    # used for error handling
    maxi = _get_next_bad(case, braces_idx)
    berr = blocks[i:i+maxi]

    # --------------------------------
    # CHECK if there are enough braces
    # > in the com case there should be at least two (name + def)
    # > in the env case there should be at least three (name + pre + post)
    if length(braces_idx) < 2 || (case == :env && length(braces_idx) < 3)
        m = """
            Not enough braces found after a \\newcommand or \\newenvironment.
            """
        return failed_block(ctx, berr, m), maxi
    end
    naming_idx = i + braces_idx[1]
    naming     = blocks[naming_idx]

    # ----------------------------
    # CHECK the following brace(s)
    next_bad = """
        The block(s) following the naming brace of a \\newcommand or
        \\newenvironment is/are incorrect, Franklin expected another brace or
        a text indicating the number of arguments followed by defining
        brace(s).
        For environments, the defining braces should not be separated (i.e.
        the closing brace and the following opening brace should touch).
        """
    # Note that since we allow spaces like \newcommand{\foo}  [1 ] {bar}
    # we should expect that after the naming brace there may be
    #   * [0/1] TEXT block with empty content
    #   * [0/1] LINK_A block with a number
    #   * [0/1] TEXT block with empty content
    #   * [1] CU_BRACKETS with the definition
    # anything else will lead to an error message
    next_idx = naming_idx + 1
    nextb    = blocks[next_idx]

    pre_space  = false
    post_space = false

    # skip if the next block is an empty text block
    if nextb.name == :TEXT
        if isempty(nextb)
            next_idx  = naming_idx + 1
            nextb     = blocks[next_idx]
            pre_space = true
        else
            return failed_block(ctx, berr, next_bad), maxi
        end
    end

    # now it should either be a [...] or a CU_BRACKETS
    nargs = 0
    has_nargs = false
    if nextb.name == :LINK_A
        # try parse it as [ . d . ]
        m = match(LX_NARGS_PAT, nextb.ss)
        m === nothing && return failed_block(ctx, block, next_bad), 0
        has_nargs = true
        nargs     = parse(Int, m.captures[1])
        # there's necessarily another brace block so can increment
        next_idx += 1
        nextb     = blocks[next_idx]
    end

    # if there was [...] then the next may be an empty TEXT
    if has_nargs && nextb.name == :TEXT
        if isempty(nextb)
            next_idx  += 1
            nextb      = blocks[next_idx]
            post_space = true
        else
            return failed_block(ctx, berr, next_bad), maxi
        end
    end

    # Now the next brace must be a brace otherwise fail
    if nextb.name != :CU_BRACKETS
        return failed_block(ctx, berr, next_bad), maxi
    end
    def = content(nextb) |> dedent |> sstrip

    # found a newcommand! push it to context and return a skipped block
    if case == :com
        name = lstrip(strip(content(naming)), '\\') |> string
        setdef!(ctx, name, LxDef(nargs, def, from(block), to(nextb)))
        # skip the naming brace, the def brace and then optionally
        # the pre-space if any, the nargs block if any, and the post space
        # so between 2 and 5 blocks taken here
        skips = 2 + pre_space + has_nargs + post_space
        return Block(:COMMENT, subs("")), skips
    end

    # if env, get one extra brace which also must be a brace
    # here we do not allow anything between the pre and post brace
    # so it must be \newenvironment{\foo} [1] {PRE}{POST}
    # with no space between PRE and POST braces
    if next_idx + 1 <= n_blocks
        nextb = blocks[next_idx + 1]
    else
        return failed_block(ctx, berr, next_bad), maxi
    end
    if nextb.name != :CU_BRACKETS
        return failed_block(ctx, berr, next_bad), maxi
    end
    pre  = def
    post = content(nextb) |> dedent |> strip |> String

    # found a newenvironment! push it to context and return a skipped block
    name = sstrip(content(naming))
    setdef!(ctx, name, LxDef(nargs, pre => post, from(block), to(nextb)))
    # see skips earlier for command, one more brace here
    skips = 3 + pre_space + has_nargs + post_space
    return Block(:COMMENT, subs("")), skips
end


function _get_next_bad(case::Symbol, braces_idx::Vector{Int})
    # The failed block should encompass the brace(s) which are immediately
    # after the `\\new*` indicator
    # --> newcommand there's 0 or 1 braces to englobe
    # --> newenvironment there's 0, 1 or 2 braces to take
    nmax = ifelse(case == :env, 2, 1)
    maxi = 0
    for (k, idx) in enumerate(first(braces_idx, nmax))
        k   != idx && break
        maxi = k
    end
    return maxi
end


"""
    try_resolve_lxcom(...)

When seeing an indicator of a command, try to resolve it with the appropriate definition
from the context. If there's no definition, either fail or leave as is if we're in maths
mode (in which case it might be something for the math engine to handle).

Return a block + the number of additional blocks taken (# of braces taken).
"""
function try_resolve_lxcom(
            i::Int,
            blocks::Vector{Block},
            lc::LocalContext;
            tohtml::Bool=true
        )::Tuple{Block,Int}

    crumbs(@fname, str_fmt(blocks[i].ss, 30))

    # Process:
    # 1. look for definition --> fail if none + not in math mode + not lxfun
    #       (if lxfun, greedily pass all subsequent braces and call the lxfun)
    # 2. extract nargs and take the next nargs blocks --> fail if not enough
    #      and if not all braces
    # 3. assemble into string and resolve
    # ------------------------------------------------------------------------
    #
    # 1 -- look for definition
    #
    cand = blocks[i]
    name = lstrip(cand.ss, '\\') |> string

    if !hasdef(lc, name)
        nsymb = Symbol(name)
        if is_in_utils(lc.glob, nsymb)
            return from_utils(nsymb, i, blocks, lc; tohtml)
        elseif lc.is_math[]
            return Block(:RAW_INLINE, cand.ss), 0
        end

        m = "Command '$(cand.ss)' used before it was defined."
        return failed_block(lc, cand, m), 0
    end
    lxdef = getdef(lc, name)

    # runtime check; lxdef should NOT be a LxDef{String=>String} otherwise
    # there's a clash in names with an environment
    if lxdef isa LxDef{Pair{String,String}}
        m = """
            There is a clashing definition of an environment with name '$name'.
            This is not allowed; use unique names for environments and commands.
            """
        return failed_block(lc, cand, m), 0
    end

    #
    # 2 -- get nargs
    #
    nargs = lxdef.nargs
    if ( i + nargs > lastindex(blocks) ||
         any(e -> e.name != :CU_BRACKETS, @view blocks[i+1:i+nargs])
        )

        m = "Not enough braces to resolve '$(cand.ss)'."
        return failed_block(lc, cand, m), 0
    end

    #
    # 3 -- assemble into string and process
    #
    r = lxdef.def::String
    # in math env, inject whitespace to avoid issues with chains; this can't happen
    # outside of maths envs as we force the use of braces
    p = ifelse(lc.is_math[], " ", "")
    # find the indicators for replacement (e.g. '#1') and replace
    @inbounds for k in 1:nargs
        c = content(blocks[i+k]) |> dedent |> strip
        # this avoids stackoverflows if the inserted content itself
        # has # (e.g. showmd with commands in the docs)
        c = replace(c, r"\#(\d)" => s"%%HASH%%\1")
        # this replacement where we keep track of whitespaces before
        # the #1 is to account for cases where the injected block has new
        # lines which should be aligned with the first injected line. See
        # issue Xranklin#34
        for w in ("!", "")
            sp = ifelse(isempty(w), p, "")
            for m in eachmatch(Regex("([ \t]*)$w#$k"), r)
                r = replace(r,
                        # either # or !#
                        "$w#$k" => sp * replace(c,
                            # preserve front spacing
                            "\n" => "\n" * m.captures[1]
                            )
                        )
            end
        end
    end
    r = replace(r, "%%HASH%%" => "#")

    recursion = ifelse(tohtml, rhtml, rlatex)
    r2 = recursion(r, lc; nop=true)
    return Block(:RAW_INLINE, subs(r2)), nargs
end


"""
    is_in_utils(gc, n; isenv)

Check if a symbol corresponds to a lx_ or env_ function in Utils.
"""
function is_in_utils(
            gc::GlobalContext,
            n::Symbol;
            isenv=false
        )::Bool

    return isenv ?
        (n in utils_envfun_names(gc)) || (n in INTERNAL_ENVFUNS) :
        (n in utils_lxfun_names(gc))  || (n in INTERNAL_LXFUNS)
end


"""
    from_utils(n, i, blocks, lc; isenv, tohtml)

Recover the lx_ or env_ function corresponding to `n`, find the relevant args,
resolve and return.
Note that if we're here we've already been through `is_in_utils` though either
the definition is in the utils module or it's internal but it exists.
"""
function from_utils(
            n::Symbol,
            i::Int,
            blocks::Vector{Block},
            lc::LocalContext;
            isenv=false,
            tohtml=true,
            brackets=Block[]
        )::Tuple{Block, Int}

    args = String[]
    if isenv
        fsymb    = Symbol("env_$n")
        kind     = :RAW_BLOCK
        internal = n in INTERNAL_ENVFUNS
        # first arg = content, next args are brackets after the env name (3,4,...)
        # \begin{foo}{bar}{baz} ... \end{foo}
        # ---> env is "..."
        # ---> args above is {foo}{bar}{baz}
        # ---> args after is ["...", "bar", "baz"]
        first_non_adjacent = 0
        for i = eachindex(brackets)
            i == 1 && continue
            if prev_index(brackets[i]) != to(brackets[i-1])
                first_non_adjacent = i
                break
            end
        end
        # first one is the name
        args_brackets = brackets[2:first_non_adjacent-1]
        # resolve args brackets (see next_adjacent_brackets)
        recursion = ifelse(tohtml, rhtml, rlatex)
        args_str  = [recursion(b, lc; nop=true) for b in args_brackets]

        # construct the string form of the brackets to send to the function
        args = [_env_content(blocks[1], length(args_str)), args_str...]

    else
        args     = next_adjacent_brackets(i, blocks, lc; tohtml)
        fsymb    = Symbol("lx_$n")
        kind     = :RAW_INLINE
        internal = n in INTERNAL_LXFUNS

    end

    o = outputof(fsymb, args, lc; internal, tohtml)
    return Block(kind, subs(o)), length(args)
end


"""
    next_adjacent_brackets(i, blocks, lc)

Take blocks `blocks[i+1, ...]` as long as their name is `:CU_BRACKETS`, resolve what's
inside them, and assemble them into a vector of raw strings that can be passed
on to a lxfun.
"""
function next_adjacent_brackets(
            i::Int, blocks::Vector{Block}, lc::LocalContext;
            tohtml::Bool=true
            )::Vector{String}

    brackets = Block[]
    c = i + 1
    @inbounds while c <= length(blocks) && blocks[c].name == :CU_BRACKETS
        push!(brackets, blocks[c])
        c += 1
    end

    return [string(content(b)) for b in brackets]
end


"""
    normalize_env_name(b)

Take a brace block corresponding to the name of an environment and return a
normalized name stripped of spaces, where internal spaces are replaced with
underscores and when `*` is converted to `_star`.
"""
function normalize_env_name(oname::SS)::String
    name = strip(oname)
    # internal spaces => underscore
    name = replace(name, r"\s"  => "_")
    # name with star => _star
    name = replace(name, "*"    => "_star")
    # repeated underscores => single underscore
    name = replace(name, r"\_+" => "_")
    return name
end


const CUB_TMPL = Dict{Symbol,FP.BlockTemplate}(e.opening => e for e in [
   FP.BlockTemplate(:CU_BRACKETS, :CU_BRACKET_OPEN, :CU_BRACKET_CLOSE, nesting=true),
   ])

"""
    try_resolve_lxenv(...)

Here the blocks are within an ENV_* group. By index:
    1.     '\\begin'
    2.     '{env_name}'
    3:n-2. content, the first block may be a brace (env args)
    n-1.   '\\end'
    n.     '{env_name}'

So there's necessarily at least 4 blocks (begin, first brace, end, last brace).
"""
function try_resolve_lxenv(
            blocks::Vector{Block},
            lc::LocalContext;
            tohtml::Bool=true
        )::Block

    crumbs(@fname)

    # recover the brackets {...} inside the environment (to read arguments)
    # there's necessarily at least two brackets (with env name)
    it       = blocks[1].inner_tokens
    brackets = Block[]
    FP._find_blocks!(brackets, it, CUB_TMPL)

    # Process:
    # 1. look for definition --> fail if none + not in math mode + not envfun
    #       (if envfun, greedily pass all subsequent braces and call)
    # 2. extract nargs and take the next nargs blocks --> fail if not enough
    #       or not all braces
    # 3. assemble into string, dedent and resolve
    # ------------------------------------------------------------------------
    oname = content(brackets[1])
    name  = normalize_env_name(oname)

    # name doesn't look good
    if !isascii(name)
        return failed_block(
            lc,
            blocks,
            "Incorrect environment name $oname, use only ascii characters."
        )
    end

    # no def for that name
    if !hasdef(lc, name)
        nsymb = Symbol(name)

        if is_in_utils(lc.glob, nsymb; isenv=true) && !is_math(lc)
            block, _ = from_utils(nsymb, 1, blocks, lc;
                                  isenv=true, tohtml, brackets)
            return block

        elseif is_math(lc)
            # resolve the inner part (e.g. if there are commands in it)
            re_s = "\\begin{$name}" *
                   math(_env_content(blocks[1]), lc; tohtml) *
                   "\\end{$name}"
            return Block(:RAW_BLOCK, subs(re_s))
        end

        m = "Environment '$(name)' used before it was defined."
        return failed_block(lc, blocks, m)
    end

    # recover the def
    lxdef = getdef(lc, name)

    # runtime check; lxdef should NOT be a LxDef{String} otherwise
    # there's a clash in names with a command
    if lxdef isa LxDef{String}
        m = """
            There is a clashing definition of a command with name '$name'.
            This is not allowed; use unique names for environments and commands.
            """
        failed_block(lc, blocks, m)
    end

    #
    # 2 -- get nargs
    #
    nargs = lxdef.nargs
    if length(brackets) < nargs + 2

        m = "Not enough braces to resolve environment '$env_name'."
        return failed_block(lc, blocks, m)
    end

    # 3 -- assemble into string and process
    def  = lxdef.def::Pair{String,String}
    pre  = def.first
    post = def.second

    @inbounds for j in 1:nargs
        c    = content(brackets[j + 1])
        pre  = replace(pre,  "#$j" => c)
        post = replace(post, "#$j" => c)
    end
    recursion = ifelse(tohtml, rhtml, rlatex)
    r  = _env_content(blocks[1], nargs)
    r2 = recursion(pre * r * post, lc)
    return Block(:RAW_BLOCK, subs(r2))
end


"""
    _env_content(block, nargs)

Helper function to extract the content of an environment block e.g.
`\\begin{foo}bar\\end{foo}` will get `bar`. The `nargs` is the number of
argument braces expected for that environment.
"""
function _env_content(block::Block, nargs::Int=0)::String
    s  = parent_string(block)
    it = block.inner_tokens
    i1 = [i for i in eachindex(it) if it[i].name == :CU_BRACKET_CLOSE][nargs + 1]
    i2 = [i for i in eachindex(it) if it[i].name == :LX_END][end]
    t1 = it[i1]
    t2 = it[i2]
    r  = subs(s, next_index(t1), prev_index(t2))
    r  = r |> dedent |> strip
    return string(r)
end
