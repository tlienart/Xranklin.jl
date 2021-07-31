const Alias  = LittleDict{Symbol, Symbol}

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
    nb_vars:            notebook associated with markdown defs in config.md
    nb_code:            notebook associated with utils.jl
    children_contexts:  associated local contexts {id => lc}

"""
struct GlobalContext{LC<:Context} <: Context
    vars::Vars
    lxdefs::LxDefs
    vars_deps::VarsDeps
    lxdefs_deps::LxDefsDeps
    vars_aliases::Alias
    nb_vars::Notebook
    nb_code::Notebook
    children_contexts::LittleDict{String, LC}
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
    nb_vars:          notebook associated with markdown defs
    nb_code:          notebook associated with the page code
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
    # notebooks
    nb_vars::Notebook
    nb_code::Notebook
end


# --------------------------------------- #
# GLOBAL CONTEXT CONSTRUCTORS AND METHODS #
# --------------------------------------- #

function GlobalContext(v=Vars(), d=LxDefs(); alias=Alias())
    vd = VarsDeps()
    ld = LxDefsDeps()
    nv = Notebook("__global_vars")
    nc = Notebook("__global_utils")
    c  = LittleDict{String, LocalContext}()
    return GlobalContext(v, d, vd, ld, alias, nv, nc, c)
end

# when a value from the global context is requested, we can track the requester
# so that, when the global context is updated, all relevant dependent pages
# can get updated as well.
function getvar(gc::GlobalContext, n::Symbol, d=nothing; requester::String="")
    n = get(gc.vars_aliases, n, n)
    isempty(requester) || add!(gc.vars_deps, n, requester)
    return getvar(gc.vars, n, d)
end

function setvar!(gc::GlobalContext, n::Symbol, v)
    n = get(gc.vars_aliases, n, n)
    setvar!(gc.vars, n, v)
end

function hasvar(gc::GlobalContext, n::Symbol)
    return n in keys(gc.vars) || n in keys(gc.vars_aliases)
end

setdef!(gc::GlobalContext, n::String, d) = setdef!(gc.lxdefs, n, d)
hasdef(gc::GlobalContext,  n::String)    = hasdef(gc.lxdefs, n)

function getdef(gc::GlobalContext, n::String; requester::String="")
    isempty(requester) || add!(gc.lxdefs_deps, n, requester)
    return getdef(gc.lxdefs, n)
end

"""
    prune_children!(gc)

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

# Note that when a local context is created it is automatically
# attached to its global context via the children_contexts
function LocalContext(g, v, d, h, id="", a=Alias())
    nv = Notebook("$(id)_vars")
    nc = Notebook("$(id)_code")
    lc = LocalContext(g, v, d, h, id, Ref(false), Ref(false),
                      Set{Symbol}(), Set{String}(), a, nv, nc)
    g.children_contexts[id] = lc
end

function LocalContext(g=GlobalContext(), v=Vars(), d=LxDefs();
                      id="", alias=Alias())
    return LocalContext(g, v, d, PageHeaders(), id, alias)
end

recursify(c::LocalContext) = (c.is_recursive[] = true; c)
mathify(c::LocalContext)   = (c.is_recursive[] = c.is_math[] = true; c)

# when trying to retrieve a variable from a local context, we first check
# whether the local context contains the variable an
function getvar(lc::LocalContext, n::Symbol, d=nothing)
    n = get(lc.vars_aliases, n, n)
    if n ∉ keys(lc.vars) && hasvar(lc.glob, n)
        # if we try to get the variable from global, keep track of that
        # see also refresh_global_context
        union!(lc.req_glob_vars, [n])
        return getvar(lc.glob, n, d; requester=lc.id)
    end
    return getvar(lc.vars, n, d)
end

function setvar!(lc::LocalContext, n::Symbol, v)
    n = get(lc.vars_aliases, n, n)
    setvar!(lc.vars, n, v)
end

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


# ------------------------ #
# NOTEBOOK FUNCTIONALITIES #
# ------------------------ #

# see also add_md_defs! defined later
function add_code!(ctx::Context, code::SS; out_path=tempname(), block_name="")
    add!(ctx.nb_code, code;
         name=block_name,
         out_path=out_path,
         block_name=block_name
    )
end

function add_vars!(ctx::Context, code::SS)
    add!(ctx.nb_vars, code; ismddefs=true, context=ctx)
end

function reset_nb_counters!(ctx::Context)
    reset_counter!(ctx.nb_vars)
    reset_counter!(ctx.nb_code)
    return
end

"""
    remove_bindings(nb, cntr)

Let's say that on pass one, there was a block defining `a=5; b=7` but then
on pass two, that the block only defines `a=5`, the binding to `b` should be
removed from the local context.

Note: it's assumed that `nb` is attached to the current lc, this is checked with
the assertion.
"""
function remove_bindings(nb::Notebook, cntr::Int)
    lc = cur_lc()
    @assert nb === lc.nb_vars  # see note in docstring
    all_bindings = Symbol[]
    for i in cntr:length(nb)
        cp = nb.code_pairs[i]
        append!(all_bindings, cp.result)
    end
    unique!(all_bindings)
    bindings_with_default = [b for b in all_bindings if b in keys(DefaultLocalVars)]
    KD = keys(DefaultLocalVars)
    for b in all_bindings
        delete!(lc.vars, b)
        if b in KD
            lc.vars[b] = DefaultLocalVars[b]
        end
    end
    return
end


# -------------------------------------- #
# LOCAL CONTEXT CONSTRUCTORS AND METHODS #
# -------------------------------------- #

"""
    set_current_global_context(gc)

Set the current global context and reset the current local context if any, in
order to guarantee consistency.
"""
function set_current_global_context(gc::GlobalContext)::GlobalContext
    setenv(:cur_global_ctx, gc)
    setenv(:cur_local_ctx, nothing)
    gc
end


"""
    set_current_local_context(lc)

Set the current local context. And since a local context is always attached to
a global context, also set the current global context to that one.
"""
function set_current_local_context(lc::LocalContext)::LocalContext
    setenv(:cur_local_ctx, lc)
    setenv(:cur_global_ctx, lc.glob)
    lc
end

# helper functions to retrieve current local/global context
cur_gc() = env(:cur_global_ctx)::GlobalContext
cur_lc() = env(:cur_local_ctx)::LocalContext

# helper functions to set var in current local/global context
setgvar!(n::Symbol, v) = setvar!(cur_gc(), n, v)
setlvar!(n::Symbol, v) = setvar!(cur_lc(), n, v)

# helper function to retrieve var in current local/global context
getgvar(n::Symbol, d=nothing) = getvar(cur_gc(), n, d)
getlvar(n::Symbol, d=nothing) = getvar(cur_lc(), n, d)


"""
    getvarfrom(id, n, d)

Retrieve a value corresponding to symbol `n` from a local context with id `s`
if it exists.
"""
function getvarfrom(id::String, n::Symbol, d=nothing)
    clc = env(:cur_local_ctx)
    (clc === nothing || id ∉ keys(clc.glob.children_contexts)) && return d
    return getvar(clc.glob.children_contexts[id], n, d)
end


# ---------------------- #
# LEGACY ACCESS COMMANDS #
# ---------------------- #

function locvar(n::Union{Symbol,String};  default=nothing)
    return getlvar(Symbol(n), default)
end

function globvar(n::Union{Symbol,String}; default=nothing)
    return getgvar(Symbol(n), default)
end

function pagevar(s::String, n::Union{Symbol,String}; default=nothing)
    return getvarfrom(s, Symbol(n), default)
end
