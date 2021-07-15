abstract type Context end


"""
    GlobalContext

Typically instantiated at config level, the global context keeps track of the
global variables and definitions.
It also keeps track of who requests a variable or definition to keep track of
what needs to be updated upon modification.

Fields:
-------
    vars: the variables accessible in the global context
    lxdefs: the lx definitions accessible in the global context
    vars_deps: keeps track of what requester needs what vars and vice versa
    lxdefs_deps: keeps track of what requester needs what lxdefs and vv
"""
mutable struct GlobalContext <: Context
    vars::Vars
    lxdefs::LxDefs
    vars_deps::VarsDeps
    lxdefs_deps::LxDefsDeps
end
GlobalContext(v=Vars(), d=LxDefs()) = GlobalContext(v, d, VarsDeps(), LxDefsDeps())

# when a value from the global context is requested, we can track the requester
# who requested the value so that, when the global context is updated,
# all relevant dependent pages get updated as well.
function value(gc::GlobalContext, n::Symbol, d=nothing; requester::String="")
    isempty(requester) || add!(gc.vars_deps, n, requester)
    return value(gc.vars, n, d)
end

setvar!(gc::GlobalContext, n::Symbol, v) = setvar!(gc.vars, n, v)
setdef!(gc::GlobalContext, n::String, d) = setdef!(gc.lxdefs, n, d)
hasdef(gc::GlobalContext, n::String)     = hasdef(gc.lxdefs, n)

function getdef(gc::GlobalContext, n::String; requester::String="")
    isempty(requester) || add!(gc.lxdefs_deps, n, requester)
    return getdef(gc.lxdefs, n)
end



"""
    LocalContext

Typically instantiated at a page level, the context keeps track of the variables,
headers, definitions etc. to specify the context in which conversion is happening.

Fields:
-------
    id: identifier for the context, typically the path of the file.
    glob: the "parent" global context
    req_glob_vars: list of global variables requested by the page
    req_glob_lxdefs: list of global lxdefs requested by the page
    vars: a dictionary of the local variables.
    lxdefs: a dictionary of the local lx-definitions.
    headers: a dictionary of the current page headers
    is_recursive: whether we're in a recursive context.
    is_math: whether we're recursing in a math environment.
"""
mutable struct LocalContext <: Context
    glob::GlobalContext
    vars::Vars
    lxdefs::LxDefs
    headers::PageHeaders
    id::String
    # chars
    is_recursive::Bool
    is_math::Bool
    # stores
    req_glob_vars::Set{Symbol}
    req_glob_lxdefs::Set{String}
end
LocalContext(g, v, d, h, id="") =
    LocalContext(g, v, d, h, id, false, false, Set{Symbol}(), Set{String}())

LocalContext(g=GlobalContext(), v=Vars(), d=LxDefs(); id="") =
    LocalContext(g, v, d, PageHeaders(), id)

recursify(c::LocalContext) = (c.is_recursive = true; c)
mathify(c::LocalContext)   = (c.is_recursive = c.is_math = true; c)


function value(lc::LocalContext, n::Symbol, d=nothing)
    if n ∉ keys(lc.vars)
        # if we try to get the variable from global, keep track of that
        union!(lc.req_glob_vars, [n])
        return value(lc.glob, n, d; requester=lc.id)
    end
    return value(lc.vars, n, d)
end

setvar!(lc::LocalContext, n::Symbol, v) = setvar!(lc.vars, n, v)
setdef!(lc::LocalContext, n::String, d) = setdef!(lc.lxdefs, n, d)

hasdef(lc::LocalContext, n::String) = hasdef(lc.lxdefs, n) || hasdef(lc.glob.lxdefs, n)

function getdef(lc::LocalContext, n::String)
    if n ∉ keys(lc.lxdefs)
        union!(lc.req_glob_lxdefs, [n])
        return getdef(lc.glob, n; requester=lc.id)
    end
    return getdef(lc.lxdefs, n)
end

"""
    refresh_global_context!(lc)

Once a string/page with id has been processed, we know on what global
variables/lxdefs it depends. As it might have changed, we refresh the global
context.
"""
function refresh_global_context!(lc::LocalContext)
    cur = lc.glob.vars_deps.bwd[lc.id]   # necessarily exists but may contain too much
    # go over the vars that are not needed by that page anymore and remove the id
    for n in setdiff(cur, lc.req_glob_vars)
        pop!(lc.glob.vars_deps.fwd[n], lc.id)
        pop!(lc.glob.vars_deps.bwd[lc.id], n)
    end
    # same for lxdefs
    cur = lc.glob.lxdefs_deps.bwd[lc.id]
    for n in setdiff(cur, lc.req_glob_lxdefs)
        pop!(lc.glob.lxdefs_deps.fwd[n], lc.id)
        pop!(lc.glob.lxdefs_deps.bwd[lc.id], n)
    end
    return
end
