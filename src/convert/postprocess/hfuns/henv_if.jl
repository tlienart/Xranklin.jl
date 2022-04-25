#= Conditional blocks

CONDS FORMAT
------------

{{if var}}
{{if e"f($var)"}}
{{if e"""f($var)"""}}

v        --> equivalent to e"$v"
e"$v"    --> equivalent to e"getlvar(:v)"
e"f($v)" --> run in utils module
e"..."  --> ANY failure and ignore code block (with warning)

=#

# ------------------------------------------------
# IF-style h-env
# > find the scope corresponding to the validated
#    condition if any
# > if a scope is found, recurse on it in context
#    `c` and write the result to `io`

"""
    resolve_henv_if(io, henv)

For a conditional henv, find the first branch that is respected and return
the scope of that branch for it to be recursed over.
"""
function resolve_henv_if(
            io::IOBuffer,
            henv::Vector{HEnvPart},
            c::Context
        )::Nothing

    env_name = first(henv).name
    scope = subs("")
    # evaluates conditions with `_check_henv_cond`
    # the first one that is validated has its scope
    # surfaced and recursed over
    for (i, p) in enumerate(henv)
        p.name == :end && continue
        flag, err = _check_cond(p, c)
        if err
            write(io, hfun_failed([env_name]))
            break
        elseif flag
            b_cur = p.block
            b_nxt = henv[i+1].block
            scope = subs(
                parent_string(b_cur),
                next_index(b_cur),
                prev_index(b_nxt)
            )
            break
        end
    end
    write(io, html2(string(scope), c))
    return
end


"""
    _check_henv_cond(p)

Return the boolean associated with condition `p` and a boolean indicating
whether there was any error resolving the condition.

Note: e-string allowed only for if/elseif.
"""
function _check_cond(
            henv::HEnvPart,
            c::Context
        )::Tuple{Bool, Bool}

    crumbs(@fname)
    env_name  = henv.name
    args      = henv.args
    flag, err = false, false

    if env_name == :else
        flag, err = _check_else(args, c)

    elseif env_name in (:if, :elseif)
        flag, err = _check_if(args, c)

    elseif env_name in (:ifdef, :isdef, :isdefined)
        flag, err = _check_isdef(args, c)

    elseif env_name in (:ifndef, :ifnotdef, :isndef, :isnotdef, :isnotdefined)
        flag, err = _check_isdef(args, c)
        flag      = !flag

    elseif env_name in (:ifempty, :isempty)
        flag, err = _check_isempty(args, c)

    elseif env_name in (:ifnempty, :ifnotempty, :isnotempty)
        flag, err = _check_isempty(args, c)
        flag      = !flag

    elseif env_name in (:ispage, :ifpage)
        flag, err = _check_ispage(args, c)

    elseif env_name in (:isnotpage, :ifnotpage)
        flag, err = _check_ispage(args, c)
        flag      = !flag

    elseif env_name in (:hasmath, :hascode)
        flag = getvar(c, env_name, false)

    elseif env_name == (:isfinal)
        flag = getvar(get_glob(c), :_final, false)

    # no other case (see hfuns/utils.jl)
    end
    return (flag, err)
end


"""
    {{else}}

Flag set to true, error is false unless arguments are passed.
"""
function _check_else(args, _)
    flag, err = true, false
    isempty(args) && return (flag, err)
    @warn """
        {{ else }}
        Found an {{else ...}} (non-empty arguments) it should be just {{else}}.
        """
    err = true
    return flag, err
end


"""
    {{isdef vname}}
    {{isdef vname1 vname2}}

Flag set to true if getting `vname` from context does not return nothing.
"""
function _check_isdef(args, c)
    flag, err = false, false
    if isempty(args)
        @warn """
            {{isdef ...}}
            Found an {{isdef}} variant without arguments (it should have at
            least one e.g. {{isdef title}}).
            """
        err = true
    else
        flag = all(a -> getvar(c, Symbol(a), nothing) !== nothing, args)
    end
    return (flag, err)
end


_isemptyvar(v::T) where T = hasmethod(isempty, (T,)) ? isempty(v) : false
_isemptyvar(::Nothing)    = true
_isemptyvar(v::Date)      = (v == Date(1))

"""
    {{isempty vname}}
    {{isempty vname1 vname2}}

Similar to isdef but checking if the relevant variables on top of being
defined are also not-empty (or non-trivial).
"""
function _check_isempty(args, c)
    flag, err = false, false
    if isempty(args)
        @warn """
            {{isempty ...}}
            Found an {{isempty}} variant without arguments (it should have at
            least one e.g. {{isempty title}}).
            """
        err = true
    else
        flag = all(a -> _isemptyvar(getvar(c, Symbol(a), nothing)), args)
    end
    return (flag, err)
end


"""
    {{ispage p1}}
    {{ispage p1 p2}}

Check if the current page matches one of the given paths.
"""
function _check_ispage(args, c::LocalContext)
    flag, err = false, false
    if isempty(args)
        @warn """
            {{ispage ...}}
            Found an {{ispage}} variant without arguments (it should have at
            least one e.g. {{ispage index.html}}).
            """
        err = true
    else
        rurl = getvar(c, :_relative_url, "")
        flag = any(a -> match_url(rurl, a), args)
    end
    return (flag, err)
end
function _check_ispage(args, c::GlobalContext)
    @warn """
        {{ispage ...}}
        Found an {{ispage ...}} called from a GlobalContext (maybe in the
        config file?). The notion of path is ambiguous and so this will be
        marked as false by default.
        """
    return (false, false)
end


"{{if ...}} or {{elseif ...}}"
function _check_if(args, c)
    flag, err = false, false
    if length(args) != 1
        @warn """
            {{if ...}} / {{elseif ...}}
            Found an {{if ...}} variant that didn't have exactly one argument.
            It should, e.g. {{if x}} or {{elseif y}}.
            """
        err = true
    else
        arg = args[1]
        if is_estr(arg)
            v = eval_str(arg)
            if v isa EvalStrError
                @warn """
                    {{if ...}} / {{elseif ...}}
                    Found and {{if ...}} variant with an e-string '$arg' that
                    failed to resolve.
                    """
                err = true
            elseif !(v isa Bool)
                @warn """
                    {{if ...}} / {{elseif ...}}
                    Found and {{if ...}} variant with an e-string '$arg' that
                    did not resolve to a boolean ('$v' of type '$(typeof(v))').
                    """
                err = true
            else
                flag = v
            end
        else
            v = getvar(c, Symbol(arg), nothing)
            if v === nothing
                @warn """
                    {{if ...}} / {{elseif ...}}
                    Found and {{if ...}} variant with an arg '$arg' that
                    couldn't be matched to a page variable.
                    """
                err = true
            elseif !(v isa Bool)
                @warn """
                    {{if ...}} / {{elseif ...}}
                    Found and {{if ...}} variant with an arg '$arg' that does
                    not resolve to a boolean ('$v' of type '$(typeof(v))').
                    """
                err = true
            else
                flag = v
            end
        end

    end
    return (flag, err)
end
