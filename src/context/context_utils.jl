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
    getvar(src, req, n, d)

Request made by context `req` for a var `n` from source context `src` with
default value `d`.

E.g.: page A requests var `:foo` from page B with default `0`

--> `src` is the lc associated with B
--> `req` is the lc associated with A
--> `n` is `:foo`
--> `d` is `0`.
"""
function getvar(
            src::GlobalContext,
            req::Union{Nothing, LocalContext},
            n::Symbol,
            d
        )

    n = get(src.vars_aliases, n, n)
    r = getvar(src.vars, n, d)

    isnothing(req) || union!(req.req_vars["__global__"], [n])
    return r
end

function getvar(
            src::LocalContext,
            req::Union{Nothing, LocalContext},
            n::Symbol,
            d=nothing
        )

    n = get(src.vars_aliases, n, n)

    # either req==lc or req is nothing
    if get_rpath(req) ∈ ("", get_rpath(src))
        lc = src
        # clash resolution gc/lc if the variable is available both
        # in lc and gc, we figure out which definition is the most relevant
        if hasvar(lc.glob, n)
            # if the lc also has the var, check that the var is not defined
            # before the current counter or has not been set via setvar
            # if both these conditions hold, use the GC
            use_global = n ∉ keys(lc.vars) || begin
                nb   = lc.nb_vars
                cntr = counter(nb)
                # not defined in a cell preceding current one
                cond = !any(
                    i ≤ cntr && any(n == v.var for v in cp.vars)
                    for (i, cp) in enumerate(nb.code_pairs)
                )
                # and not set
                cond && n ∉ get(lc.vars, :_setvar, Set{Symbol}())
            end
            if use_global
                union!(lc.req_vars["__global__"], [n])
                return getvar(lc.glob.vars, n, d)
            end
        end

    # getvarfrom case, add the variable as requested
    else
        if n in keys(src.vars)
            req.req_vars[src.rpath] = union(
                get(req.req_vars, src.rpath, Set{Symbol}()),
                [n]
            )

        end

    end

    return getvar(src.vars, n, d)
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
getdef(gc::GlobalContext,  n::String)    = getdef(gc.lxdefs, n)
setdef!(gc::GlobalContext, n::String, d) = setdef!(gc.lxdefs, n, d)
setdef!(lc::LocalContext,  n::String, d) = setdef!(lc.lxdefs, n, d)

# for hasdef, check the local context then the global context
hasdef(lc::LocalContext, n::String) =
    hasdef(lc.lxdefs, n) || hasdef(lc.glob.lxdefs, n)

function getdef(lc::LocalContext, n::String)
    if n ∉ keys(lc.lxdefs) && hasdef(lc.glob, n)
        union!(lc.req_lxdefs, [n])
        return getdef(lc.glob, n)
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
attach(lc::LocalContext, dep_rpath::String) =
    push!(lc.glob.deps_map, lc.rpath, dep_rpath)
