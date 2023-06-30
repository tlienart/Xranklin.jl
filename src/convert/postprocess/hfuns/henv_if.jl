#= Conditional blocks

CONDS FORMAT
------------

{{if var}}
{{if e"f($var)"}}
{{if e"""f($var)"""}}

v        --> equivalent to e"$v"
e"$v"    --> equivalent to e"getlvar(:v)"
e"f($v)" --> run in utils module
e"..."   --> ANY failure and ignore code block (with warning)

1. resolve the e-string (which may be a variable name)


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
            lc::LocalContext,
            io::IOBuffer,
            henv::Vector{HEnvPart},
        )::Nothing

    env_name = first(henv).name

    scope = subs("")
    # evaluates conditions with `_check_henv_cond`
    # the first one that is validated has its scope
    # surfaced and recursed over
    for (i, p) in enumerate(henv)
        p.name == :end && continue
        flag, err = _check_cond(lc, p)
        if err
            write(io, hfun_failed([string.(env_name)]))
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
    write(io, html2(string(scope), lc))
    return
end


"""
    _check_henv_cond(lc, p)

Return the boolean associated with condition `p` and a boolean indicating
whether there was any error resolving the condition.

### With arg, may be an e-string

* if, elseif         | basic condition
* ifempty, ifnempty  | condition based on emptiness

### With arg, may only be a string

* ifdef, ifndef      | condition based on existence of var
* ifpage, ifnotpage  | condition based on relative path

### Without arg

* hasmath, hascode   | condition based on presence of math/code
* isfinal            | check if we're in the final build, can be used to adjust
                       path prefix and differentiate between development where
                       the prepath should not be injected, and the final build
                       where it should.

### Returns

The function returns a bool tuple (flag, err) where

    * `flag` indicates true/false (gate passing or not)
    * `err` indicates whether something errorred (e.g. wrong syntax)
"""
function _check_cond(
            lc::LocalContext,
            henv::HEnvPart,
        )::Tuple{Bool, Bool}

    crumbs(@fname)
    env_name  = henv.name
    args      = henv.args
    flag, err = false, false

    if env_name == :else
        flag, err = _check_else(lc, args)

    elseif env_name in (:if, :elseif)
        flag, err = _check_if(lc, args)

    elseif env_name in (:ifdef, :isdef, :isdefined)
        flag, err = _check_isdef(lc, args)

    elseif env_name in (:ifnotdef, :isnotdef, :isnotdefined)
        flag, err = _check_isdef(lc, args)
        flag      = !flag

    elseif env_name in (:ifempty, :isempty)
        flag, err = _check_isempty(lc, args)

    elseif env_name in (:ifnotempty, :isnotempty)
        flag, err = _check_isempty(lc, args)
        flag      = !flag

    elseif env_name in (:ispage, :ifpage)
        flag, err = _check_ispage(lc, args)

    elseif env_name in (:isnotpage, :ifnotpage)
        flag, err = _check_ispage(lc, args)
        flag      = !flag

    elseif env_name in (:hasmath, :hascode)
        flag = getvar(lc, env_name, false)

    elseif env_name == (:isfinal)
        flag = getvar(lc.glob, :_final, false)

    # no other case (see hfuns/utils.jl)
    end
    return (flag, err)
end


"""
    {{else}}

Flag set to true, error is false unless arguments are passed.
"""
function _check_else(_, args)
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
function _check_isdef(lc, args)
    flag, err = false, false
    if isempty(args)
        @warn """
            {{isdef ...}}
            Found an {{isdef}} variant without arguments (it should have at
            least one e.g. {{isdef title}}).
            """
        err = true
    else
        # go over all args, try to retrieve them, and check that they're not
        # nothing
        flag = all(
            a -> getvar(lc, Symbol(a), nothing) !== nothing,
            args
        )
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
function _check_isempty(lc, args)
    flag, err = false, false
    if isempty(args)
        @warn """
            {{isempty ...}}
            Found an {{isempty}} variant without arguments (it should have at
            least one e.g. {{isempty title}}).
            """
        err = true
    else
        flag = true
        for a in args
            flag &= begin
                if is_estr(a)
                    res = eval_str(lc, a)
                    if !res.success
                        err = true
                        false
                    else
                        _isemptyvar(res.value)
                    end
                else
                    _isemptyvar(getvar(lc, Symbol(a), nothing))
                end
            end
        end
    end
    return (flag, err)
end


"""
    {{ispage p1}}
    {{ispage p1 p2}}

Check if the current page matches one of the given paths. Paths can be given
as e-strings.
"""
function _check_ispage(lc, args)
    flag, err = false, false
    if isempty(args)
        @warn """
            {{ispage ...}}
            Found an {{ispage}} variant without arguments (it should have at
            least one e.g. {{ispage index.html}}).
            """
        err = true
    else
        rurl = getvar(lc, :_relative_url, "")
        if any(is_estr, args)
            args = [is_estr(arg) ? eval_str(lc, arg).value : arg for arg in args]
        end
        
        flag = any(a -> match_url(rurl, a), args)
    end
    return (flag, err)
end


"{{if ...}} or {{elseif ...}}"
function _check_if(lc, args)
    flag, err = false, false
    comb_args = prod(args)

    if is_estr(comb_args)
        res = eval_str(lc, comb_args)
        if !res.success
            err = true
        elseif !(res.value isa Bool)
            @warn """
                {{if ...}} / {{elseif ...}}
                Found and {{if ...}} variant with an e-string '$arg' that
                did not resolve to a boolean ('$(res.value)' of type
                '$(typeof(res.value))').
                """
            err = true
        else
            flag = res.value
        end

    elseif length(args) == 1
        arg = args[1]
        v = getvar(lc, Symbol(arg))
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
        
    else
        @warn """
            {{if ...}} / {{elseif ...}}
            Found an {{if ...}} variant that didn't have exactly one argument or
            an e-string. It be should, e.g. {{if x}} or {{elseif y}}.
            """
        err = true
    end
    return (flag, err)
end
