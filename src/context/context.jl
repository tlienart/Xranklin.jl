const VarsCodePair = NamedTuple{(:code, :vars),  Tuple{String, Vector{Symbol}}}
const CodeRepr     = NamedTuple{(:html, :latex), Tuple{String, String}}
const CodeCodePair = NamedTuple{(:code, :repr),  Tuple{String, CodeRepr}}

const VarsCodePairs = Vector{VarsCodePair}
const CodeCodePairs = Vector{CodeCodePair}

const CodeMap = LittleDict{String, Int}


"""
    Notebook

Structure wrapping around a module in which code gets evaluated sequentially.
A Notebook is always contained within a context and is always accessed via
that context.
"""
abstract type Notebook end


"""
    VarsNotebook

Notebook for vars assignments.

## Fields

    mdl:        the module in which code gets evaluated
    cntr_refs:  keeps track of the evaluated "cell number" when sequentially
                 evaluating code
    code_pairs: keeps track of [(code => vnames)]
"""
struct VarsNotebook <: Notebook
    mdl::Module
    cntr_ref::Ref{Int}
    code_pairs::VarsCodePairs
    is_stale_ref::Ref{Bool}
end

"""
    CodeNotebook

Notebook for code.

## Fields

Same as VarsNotebook with

    code_map: keeps track of {code_name => cntr}
"""
struct CodeNotebook <: Notebook
    mdl::Module
    cntr_ref::Ref{Int}
    code_pairs::CodeCodePairs
    code_map::LittleDict{String, Int}
    is_stale_ref::Ref{Bool}
end

isstale(nb::Notebook) = nb.is_stale_ref[]
stale_notebook!(nb::Notebook) = (nb.is_stale_ref[] = true;)
fresh_notebook!(nb::Notebook) = (nb.is_stale_ref[] = false;)

# ------------------------------ #
# GLOBAL and LOCAL CONTEXT TYPES #
# ------------------------------ #

# allows to have several varname for the same effect (e.g. prepath, base_url_prefix)
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
    vars_aliases:       other accepted names for default variables
    nb_vars:            notebook associated with markdown defs in config.md
    nb_code:            notebook associated with utils.jl
    children_contexts:  associated local contexts {rpath => lc}
    to_trigger:         set of dependent pages to trigger after updating GC

"""
struct GlobalContext{LC<:Context} <: Context
    vars::Vars
    lxdefs::LxDefs
    vars_aliases::Alias
    nb_vars::VarsNotebook
    nb_code::CodeNotebook
    children_contexts::LittleDict{String, LC}
    to_trigger::Set{String}
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
    rpath:            relative path to the page with this local context.
    is_recursive:     whether we're in a recursive context
    is_math:          whether we're recursing in a math environment
    req_vars:         mapping {pg => set of vars requested from pg}
    req_lxdefs:       mapping {pg => set of defs requested from pg}
    vars_aliases:     other accepted names for default variables
    nb_vars:          notebook associated with markdown defs
    nb_code:          notebook associated with the page code
    to_trigger:       set of dependent pages to trigger after updating LC

Note: for req_lxdefs, there is only one other context from which one can get
def, the global context, but we use the same structure for symmetry with
req_vars (for which it does make sense to request variables from other pages).
"""
struct LocalContext <: Context
    glob::GlobalContext
    vars::Vars
    lxdefs::LxDefs
    headers::PageHeaders
    rpath::String
    # chars
    is_recursive::Ref{Bool}
    is_math::Ref{Bool}
    # stores
    req_vars::LittleDict{String, Set{Symbol}}
    req_lxdefs::LittleDict{String, Set{String}}
    vars_aliases::Alias
    # notebooks
    nb_vars::VarsNotebook
    nb_code::CodeNotebook
    to_trigger::Set{String}
end


isglob(::GlobalContext) = true
isglob(::LocalContext)  = false

getid(::GlobalContext)::String = "__global"
getid(c::LocalContext)::String = c.rpath

getglob(c::GlobalContext)::GlobalContext = c
getglob(c::LocalContext)::GlobalContext  = c.glob


# --------------------------------------- #
# GLOBAL CONTEXT CONSTRUCTORS AND METHODS #
# --------------------------------------- #

function GlobalContext(v=Vars(), d=LxDefs(); alias=Alias())
    # vars notebook
    mdl = submodule(modulename("__global_vars", true), wipe=true)
    nv  = VarsNotebook(mdl, Ref(1), VarsCodePairs(), Ref(false))
    # utils notebook
    mdl = submodule(modulename("__global_utils", true), wipe=true)
    nc  = CodeNotebook(mdl, Ref(1), CodeCodePairs(), CodeMap(), Ref(false))
    # children
    c   = LittleDict{String, LocalContext}()
    # to_trigger
    tt  = Set{String}()
    return GlobalContext(v, d, alias, nv, nc, c, tt)
end

function hasvar(gc::GlobalContext, n::Symbol)
    return n in keys(gc.vars) || n in keys(gc.vars_aliases)
end

function getvar(gc::GlobalContext, n::Symbol, d=nothing)
    n = get(gc.vars_aliases, n, n)
    return getvar(gc.vars, n, d)
end

function setvar!(gc::GlobalContext, n::Symbol, v)
    n = get(gc.vars_aliases, n, n)
    setvar!(gc.vars, n, v)
end

hasdef(gc::GlobalContext,  n::String)    = hasdef(gc.lxdefs, n)
getdef(gc::GlobalContext,  n::String)    = getdef(gc.lxdefs, n)
setdef!(gc::GlobalContext, n::String, d) = setdef!(gc.lxdefs, n, d)


"""
    prune_children!(gc)

Remove children if their rpath does not correspond to an existing page.
This can happen if, during a session, a page `page1.md` is created, has its
local context that gets appended to the list of children of the global
context, then the user renames the file `page2.md`. The rpath `page1.md`
does then not correspond to an existing page anymore and should be popped.

This function should be called whenever `.md` pages are removed in the server
loop.
"""
function prune_children!(gc::GlobalContext)
    for (k, v) in gc.children_contexts
        isfile(v.rpath) && continue
        pop!(gc.children_contexts, k)
    end
end


# -------------------------------------- #
# LOCAL CONTEXT CONSTRUCTORS AND METHODS #
# -------------------------------------- #

# Note that when a local context is created it is automatically
# attached to its global context via the children_contexts
function LocalContext(glob, vars, defs, headers, rpath="", alias=Alias())
    # vars notebook
    mdl = submodule(modulename("$(rpath)_vars", true), wipe=true)
    nv  = VarsNotebook(mdl, Ref(1), VarsCodePairs(), Ref(false))
    # code notebook
    mdl = submodule(modulename("$(rpath)_code", true), wipe=true)
    nc  = CodeNotebook(mdl, Ref(1), CodeCodePairs(), CodeMap(), Ref(false))
    # req vars (keep track of what is requested by this page)
    rv = LittleDict{String, Set{Symbol}}(
        "__global" => Set{Symbol}()
    )
    rl = LittleDict{String, Set{String}}(
        "__global" => Set{String}()
    )
    tt = Set{String}()
    # form the object
    lc = LocalContext(glob, vars, defs, headers,
                      rpath, Ref(false), Ref(false),
                      rv, rl, alias, nv, nc, tt)
    # attach it to global
    glob.children_contexts[rpath] = lc
    return lc
end

function LocalContext(g=GlobalContext(), v=Vars(), d=LxDefs();
                      rpath="", alias=Alias())
    return LocalContext(g, v, d, PageHeaders(), rpath, alias)
end

recursify(c::LocalContext) = (c.is_recursive[] = true; c)
mathify(c::LocalContext)   = (c.is_recursive[] = c.is_math[] = true; c)

# when trying to retrieve a variable from a local context, we first check
# whether the local context contains the variable, if it doesn't but the
# global context has it, then get from global
function getvar(lc::LocalContext, n::Symbol, d=nothing)
    n = get(lc.vars_aliases, n, n)
    if hasvar(lc.glob, n)
        # check whether to use the global definition or not, use global if
        # 1. there's no clash
        # 2. there's a clash but there's no local assignment or setvar!
        use_global =
            # 1. no clash
            n ∉ keys(lc.vars) ||
            # 2. clash but no loc assign and no setvar assign
            begin
                nb   = lc.nb_vars
                cntr = counter(nb)
                f1   = !any(
                    i ≤ cntr && n in cp.vars
                    for (i, cp) in enumerate(nb.code_pairs)
                )
                f1 && n ∉ get(lc.vars, :_setvar, Set{Symbol}())::Set{Symbol}
            end

        if use_global
            # if we try to get the variable from global, keep track of that
            union!(lc.req_vars["__global"], [n])
            return getvar(lc.glob, n, d)
        end
    end
    return getvar(lc.vars, n, d)
end

function setvar!(lc::LocalContext, n::Symbol, v)
    n = get(lc.vars_aliases, n, n)
    # to ensure that this assignment takes over any global assignment,
    # keep track of it (see getvar above)
    union!(get(lc.vars, :_setvar, Set{Symbol}()), [n])
    setvar!(lc.vars, n, v)
end

setdef!(lc::LocalContext, n::String, d) = setdef!(lc.lxdefs, n, d)

# for hasdef, check the local context then the global context
hasdef(lc::LocalContext, n::String) =
    hasdef(lc.lxdefs, n) || hasdef(lc.glob.lxdefs, n)

function getdef(lc::LocalContext, n::String)
    if n ∉ keys(lc.lxdefs) && hasdef(lc.glob, n)
        union!(lc.req_lxdefs["__global"], [n])
        return getdef(lc.glob, n)
    end
    return getdef(lc.lxdefs, n)
end


"""
    getvarfrom(rpath, n, d)

Retrieve a value corresponding to symbol `n` from a local context with rpath
`rpath` if it exists.
"""
function getvarfrom(rpath::String, n::Symbol, d=nothing)
    # is there such an rpath in current GC ? if not but the rpath corresponds
    # to a file, then trigger a process of that file and try again
    clc = env(:cur_local_ctx)
    clc === nothing && return d
    glob = clc.glob
    if rpath ∉ keys(glob.children_contexts)
        # if there's no file at that rpath, process_md_file will not do
        # anything and the default will be returned later
        process_md_file(glob, rpath)
        # if rpath didn't correspond to a file then it's still not in the children
        # contexts key and we should return the default
        rpath ∉ keys(glob.children_contexts) && return d
    end
    # here we do have rpath as a child, add the relevant symbol as a requested
    # variable and return the value
    ctx = glob.children_contexts[rpath]
    n = get(ctx.vars_aliases, n, n)
    if n in keys(ctx.vars)
        clc.req_vars[rpath] = union!(
            get(clc.req_vars, rpath, Set{Symbol}()),
            [n]
        )
    end
    return getvar(glob.children_contexts[rpath], n, d)
end


# ----------------------- #
# CURRENT GC / CURRENT LC #
# ----------------------- #

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

cur_utils_module() = cur_gc().nb_code.mdl

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
