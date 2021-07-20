const Alias  = LittleDict{Symbol,Symbol}

abstract type Context end


"""
    GlobalContext

Typically instantiated at config level, the global context keeps track of the
global variables and definitions of a session. There's usually just one for
the whole site. It also keeps track of who requests a variable or definition
to keep track of what needs to be updated upon modification.

Fields:
-------
    vars:               the variables accessible in the global context
    lxdefs:             the lx definitions accessible in the global context
    vars_deps:          keeps track of requester <-> vars
    lxdefs_deps:        keeps track of requester <-> lxdefs
    vars_aliases:       other accepted names for default variables
    children_contexts:  associated local contexts {id => lc}
"""
struct GlobalContext{LC<:Context} <: Context
    vars::Vars
    lxdefs::LxDefs
    vars_deps::VarsDeps
    lxdefs_deps::LxDefsDeps
    vars_aliases::Alias
    children_contexts::LittleDict{String,LC}
end


"""
    LocalContext

Typically instantiated at a page level, the context keeps track of the
variables, headers, definitions etc. to specify the context in which the
conversion is happening.

Fields:
-------
    glob:             the "parent" global context
    vars:             a dictionary of the local variables
    lxdefs:           a dictionary of the local lx-definitions
    headers:          a dictionary of the current page headers
    id:               id for the context, typically the path of the file
    is_recursive:     whether we're in a recursive context
    is_math:          whether we're recursing in a math environment
    req_glob_vars:    set of global variables requested by the page
    req_glob_lxdefs:  set of global lxdefs requested by the page
    vars_aliases:     other accepted names for default variables
"""
struct LocalContext <: Context
    glob::GlobalContext
    vars::Vars
    lxdefs::LxDefs
    headers::PageHeaders
    id::String
    # chars
    is_recursive::Ref{Bool}
    is_math::Ref{Bool}
    # stores
    req_glob_vars::Set{Symbol}
    req_glob_lxdefs::Set{String}
    vars_aliases::Alias
end

# --------------------------------------- #
# GLOBAL CONTEXT CONSTRUCTORS AND METHODS #
# --------------------------------------- #

function GlobalContext(v=Vars(), d=LxDefs(); alias=Alias())
    vd = VarsDeps()
    ld = LxDefsDeps()
    c  = LittleDict{String,LocalContext}()
    GlobalContext(v, d, vd, ld, alias, c)
end

# when a value from the global context is requested, we can track the requester
# so that, when the global context is updated, all relevant dependent pages
# can get updated as well.
function value(gc::GlobalContext, n::Symbol, d=nothing; requester::String="")
    n = get(gc.vars_aliases, n, n)
    isempty(requester) || add!(gc.vars_deps, n, requester)
    return value(gc.vars, n, d)
end

setvar!(gc::GlobalContext, n::Symbol, v) = setvar!(gc.vars, n, v)
setdef!(gc::GlobalContext, n::String, d) = setdef!(gc.lxdefs, n, d)
hasdef(gc::GlobalContext,  n::String)    = hasdef(gc.lxdefs, n)

function getdef(gc::GlobalContext, n::String; requester::String="")
    isempty(requester) || add!(gc.lxdefs_deps, n, requester)
    return getdef(gc.lxdefs, n)
end

"""
    prune_children!

Remove children if their id does not correspond to an existing page.
This can happen if, during a session, a page `page1.md` is created, has its
local context that gets appended to the list of children of the global
context, then the user renames the file `page2.md`. The id `page1.md`
does then not correspond to an existing page anymore and should be popped.

This function should be called whenever `.md` pages are removed in the server
loop.
"""
function prune_children!(gc::GlobalContext)
    for (k, v) in gc.children_contexts
        isfile(v.id) && continue
        pop!(gc.children_contexts, k)
    end
end

# -------------------------------------- #
# LOCAL CONTEXT CONSTRUCTORS AND METHODS #
# -------------------------------------- #

function LocalContext(g, v, d, h, id="", a=Alias())
    lc = LocalContext(g, v, d, h, id, Ref(false), Ref(false),
                      Set{Symbol}(), Set{String}(), a)
    g.children_contexts[id] = lc
end

function LocalContext(g=GlobalContext(), v=Vars(), d=LxDefs();
                      id="", alias=Alias())
    return LocalContext(g, v, d, PageHeaders(), id, alias)
end

recursify(c::LocalContext) = (c.is_recursive[] = true; c)
mathify(c::LocalContext)   = (c.is_recursive[] = c.is_math[] = true; c)

function value(lc::LocalContext, n::Symbol, d=nothing)
    n = get(lc.vars_aliases, n, n)
    if n ∉ keys(lc.vars)
        # if we try to get the variable from global, keep track of that
        # see also refresh_global_context
        union!(lc.req_glob_vars, [n])
        return value(lc.glob, n, d; requester=lc.id)
    end
    return value(lc.vars, n, d)
end

setvar!(lc::LocalContext, n::Symbol, v) = setvar!(lc.vars, n, v)
setdef!(lc::LocalContext, n::String, d) = setdef!(lc.lxdefs, n, d)

# for hasdef, check the local context then the global context
hasdef(lc::LocalContext, n::String) =
    hasdef(lc.lxdefs, n) || hasdef(lc.glob.lxdefs, n)

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
variables/lxdefs it depends. As this might have changed since the previous
time we processed that string/page, we refresh the global context with that
info.
"""
function refresh_global_context!(lc::LocalContext)
    # cur below necessarily exists but may contain too much which we'll prune
    cur = lc.glob.vars_deps.bwd[lc.id]
    # go over the vars that are not needed by that page anymore and prune
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


# -------------------------------------- #
# LOCAL CONTEXT CONSTRUCTORS AND METHODS #
# -------------------------------------- #

"""
    set_current_local_context(lc)

Set the current local context (and the global context that it points to).
"""
function set_current_local_context(lc::LocalContext)
    FRANKLIN_ENV[:CUR_LOCAL_CTX] = lc
    return nothing
end

value(::Nothing, n::Symbol, d=nothing) = d
value(n::Symbol, d=nothing) = value(FRANKLIN_ENV[:CUR_LOCAL_CTX], n, d)

"""
    valuefrom(id, n, d)

Retrieve a value correpsonding to symbol `n` from a local context with id `s`
if it exists.
"""
function valuefrom(id::String, n::Symbol, d=nothing)
    clc = FRANKLIN_ENV[:CUR_LOCAL_CTX]
    (clc === nothing || id ∉ keys(clc.glob.children_contexts)) && return d
    return value(clc.glob.children_contexts[id], n, d)
end


# ---------------------- #
# LEGACY ACCESS COMMANDS #
# ---------------------- #

function locvar(n::Union{Symbol,String};  default=nothing)
    return value(Symbol(n), default)
end

function globvar(n::Union{Symbol,String}; default=nothing)
    clc = FRANKLIN_ENV[:CUR_LOCAL_CTX]
    clc === nothing && return default
    return value(clc.glob, Symbol(n), default)
end

function pagevar(s::String, n::Union{Symbol,String}; default=nothing)
    return valuefrom(s, Symbol(n), default)
end
