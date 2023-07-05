is_glob(::GlobalContext) = true
is_glob(::LocalContext)  = false

# available to user via get_rpath (see `modules_setup`)
get_rpath(::GlobalContext) = "__global__"
get_rpath(c::LocalContext) = c.rpath
get_rpath(::Nothing)       = ""

get_glob(c::GlobalContext) = c
get_glob(c::LocalContext)  = c.glob

is_recursive(c::GlobalContext) = false
is_recursive(c::LocalContext)  = c.is_recursive[]

set_recursive!(c::GlobalContext) = c
set_recursive!(c::LocalContext)  = (c.is_recursive[] = true; c)

is_math(c::GlobalContext) = false
is_math(c::LocalContext)  = c.is_math[]


function hasvar(gc::GlobalContext, n::Symbol)
    return n in keys(gc.vars) || n in keys(gc.vars_aliases)
end

"""
    req_var!(src, req, req_var, default)

Add the requested var `req_var` to the source context `req_vars` indicating
that the requester context is `req` (possibly nothing).

Return the variable.
"""
function req_var!(
            src::Context,
            req::Union{Nothing, LocalContext},
            req_var::Symbol,
            default
        )
    if !isnothing(req)
        # if there's already an entry for that requester, just extend it
        if req.rpath in keys(src.req_vars)
            union!(src.req_vars[req.rpath], [req_var])
        # otherwise create one
        else
            src.req_vars[req.rpath] = Set([req_var])
        end
    end
    return get(src.vars, req_var, default)
end


"""
    getvar(src, req, n, d)

Request made by context `req` for a var `n` from source context `src` with
default value `d`.

E.g.: page A requests var `:foo` from page B with default `0`

--> `src` is the lc associated with B
--> `req` is the lc associated with A
--> `n` is `:foo`
--> `d` is `0`.

## Cases

See `modules_setup`

* getlvar    --> src == cur_lc ; req == cur_lc  [ also locvar  ]
* getgvar    --> src == cur_gc ; req == cur_lc  [ also globvar ]
* getvarfrom --> src == xxx_lc ; req == cur_lc  [ also pagevar ]

Recall that cur_lc/cur_gc can be nothing if there isn't one.
"""
function getvar(
            src::GlobalContext,
            req::Union{Nothing, LocalContext},
            req_var::Symbol,
            default
        )
    # recover the 'canonical' variable name
    req_var_nrm = get(src.vars_aliases, req_var, req_var)
    return req_var!(src, req, req_var_nrm, default)
end

function getvar(
            src::LocalContext,
            req::Union{Nothing, LocalContext},
            req_var::Symbol,
            default=nothing
        )

    src_rpath   = get_rpath(src)
    req_rpath   = get_rpath(req)
    req_var_nrm = get(src.vars_aliases, req_var, req_var)

    if req_rpath ∉ ("", src_rpath)
        # This is the case where the req_rpath is non-trivial and different
        # from src_rpath which comes from a `pagevarfrom` call.
        return req_var!(src, req, req_var_nrm, default)
    end

    # Here we're in the other cases where either
    #  * src == lc == req (standard getlvar)
    #  * src == lc and req === nothing (other getlvar)
    #
    # We first check whether the variable is available in GC, if it is then we
    # need to see if that's more relevant than extracting it from LC:
    #   1. SRC LC doesn't have the var --> use GC
    #   2. SRC LC does have the var
    #      2.a the definition is not before the current cell --> use GC
    #      2.b the definition is before the current cell --> use SRC LC
    #      2.c the assignment is in the current cell before the current
    #          getvar --> use SRC LC 
    if hasvar(src.glob, req_var_nrm)
        use_global = req_var_nrm ∉ keys(src.vars) || begin
            nb   = src.nb_vars
            cntr = counter(nb)
            # not defined in a cell preceding current one
            cond = !any(
                i ≤ cntr && any(req_var_nrm == v.var for v in cp.vars)
                for (i, cp) in enumerate(nb.code_pairs)
            )
            # and not set in current cell ahead of the getvar call
            cond && (req_var_nrm ∉ get(src.vars, :_setvar, Set{Symbol}()))
        end
        if use_global
            # in that case the source is actually glob, and the
            # requester is src
            return req_var!(src.glob, src, req_var_nrm, default)
        end
    end
    # if we got here then GC is not an appropriate context to recover the
    # variable, we jump to the return statement at the end which tries to
    # retrieve the statement from LC
    return getvar(src.vars, req_var_nrm, default)
end

getvar(::Nothing, a...) = nothing
getvar(src::Context, n::Symbol, d=nothing; default=d) =
    getvar(src, nothing, n, default)


function setvar!(gc::GlobalContext, n::Symbol, v)
    n = get(gc.vars_aliases, n, n)
    setvar!(gc.vars, n, v)
end

function setvar!(lc::LocalContext, n::Symbol, v)
    n = get(lc.vars_aliases, n, n)
    # to ensure that this assignment takes over any global assignment,
    # keep track of it (see getvar above)
    union!(get(lc.vars, :_setvar, Set{Symbol}()), [n])
    setvar!(lc.vars, n, v)
end

setvar!(::Nothing, a...) = nothing


hasdef(gc::GlobalContext,  n::String)    = hasdef(gc.lxdefs, n)
setdef!(gc::GlobalContext, n::String, d) = setdef!(gc.lxdefs, n, d)
setdef!(lc::LocalContext,  n::String, d) = setdef!(lc.lxdefs, n, d)

# for hasdef, check the local context then the global context
hasdef(lc::LocalContext, n::String) =
    hasdef(lc.lxdefs, n) || hasdef(lc.glob.lxdefs, n)

function getdef(
            gc::GlobalContext,
            n::String;
            req::Union{Nothing, LocalContext}=nothing
        )
    if !isnothing(req)
        req_rpath = get_rpath(req)
        if req_rpath in keys(gc.req_lxdefs)
            union!(gc.req_lxdefs[req_rpath], [n])
        else
            gc.req_lxdefs[req_rpath] = Set([n])
        end
    end
    return getdef(gc.lxdefs, n)
end

function getdef(lc::LocalContext, n::String)
    if n ∉ keys(lc.lxdefs) && hasdef(lc.glob, n)
        return getdef(lc.glob, n; req=lc)
    end
    return getdef(lc.lxdefs, n)
end


"""
    set_current_global_context(gc)

Set the current global context and reset the current local context if any, in
order to guarantee consistency.
"""
function set_current_global_context(gc::GlobalContext)::GlobalContext
    setenv!(:cur_global_ctx, gc)
    gc
end

# helper functions to retrieve current local/global context
cur_gc() = env(:cur_global_ctx)::GlobalContext


# ---------------- #
# DEPS MAP RELATED #
# ---------------- #

"""
    attach(lc, dep_rpath)

Add the dependency `lc` to the file at `dep_rpath` to the global dependency 
map.

This is used internally to attach a literate file to the page(s)
that call(s) it.

DEV:
    - context/deps_map.jl
    - convert/markdown/lxfuns/literate.jl (_process_literate_file)
"""
function attach(lc::LocalContext, dep_rpath::String)
    push!(lc.glob.deps_map, lc.rpath, dep_rpath)
end
