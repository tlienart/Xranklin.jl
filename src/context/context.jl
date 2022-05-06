abstract type Context end

# allows to have several varname for the same effect (e.g. prepath, base_url_prefix)
const Alias = Dict{Symbol, Symbol}


"""
    GlobalContext

The global context keeps track of the global variables and definitions of a
session. There's one for the whole site.
It also keeps track of what page requests a variable or definition to keep
track of what needs to be updated upon modification.

## Fields

    vars              : the variables accessible in the global context
    lxdefs            : the lx definitions accessible in the global context
    vars_aliases      : other accepted names for default variables
    nb_vars           : notebook associated with markdown defs in config file
    nb_code           : notebook associated with utils file
    anchors           : dictionary of all anchors {id => Anchor}
    tags              : dictionary of all tags {id => Tag}
    paginated         : set of pages `{rpath}` which are paginated
    children_contexts : associated local contexts {rpath => lc}
    to_trigger        : set of dependent pages to trigger after updating GC
                         (e.g. if config redefines a var used by some pages)
    init_trigger      : set of pages to trigger a second time after the initial
                         full pass so they have access to everything defined in
                         the full pass (e.g. all anchors).
    deps_map          : data structure keeping track of what markdown pages
                         depends on what files (e.g. literate scripts) and vice
                         versa, to check whether a page needs to be updated.

### Note on `init_trigger`

Generally it is 'to_trigger' that is used. The logic there is that when a page
queries directly from GC we know that arrow (pg -> GC) and so when GC gets
updated we necessarily need to go the other way (GC -> pg). When a page
requires from another page (pg1 -> pg2) then this is handled via pg2's
LC.to_trigger.

However in some cases like the anchors, pages might request an information from
another page without knowing which page provides it. In this context these
pages need to be re-processed after the initial full pass so that they can
'find' the right provider page. That's what the init_trigger is for.
"""
struct GlobalContext{LC<:Context} <: Context
    vars::Vars
    lxdefs::LxDefs
    vars_aliases::Alias
    nb_vars::VarsNotebook
    nb_code::CodeNotebook
    anchors::Dict{String, Anchor}
    tags::Dict{String, Tag}
    paginated::Set{String}
    children_contexts::Dict{String, LC}
    to_trigger::Set{String}
    init_trigger::Set{String}
    deps_map::DepsMap
end


"""
    LocalContext

Typically instantiated at a page level, the context keeps track of the
variables, headings, definitions etc. to specify the context in which the
conversion is happening.

## Fields

    glob:             the parent context
    vars:             a dictionary of the local variables
    lxdefs:           a dictionary of the local lx-definitions
    headings:         a dictionary of the current page headings
    rpath:            relative path to the page with this local context
                       this includes the extension so e.g. foo/bar/baz.md
    anchors:          set of anchor ids defined on the page
    is_recursive:     whether we're in a recursive context
    is_math:          whether we're recursing in a math environment
    req_vars:         mapping {pg => set of vars requested from pg}
    req_lxdefs:       set of lxdefs names requested by the page from global
    vars_aliases:     other accepted names for default variables
    nb_vars:          notebook associated with markdown defs
    nb_code:          notebook associated with the page code
    to_trigger:       set of dependent pages to trigger after updating LC

"""
struct LocalContext <: Context
    glob::GlobalContext
    vars::Vars
    lxdefs::LxDefs
    headings::PageHeadings
    rpath::String
    anchors::Set{String}
    # chars
    is_recursive::Ref{Bool}
    is_math::Ref{Bool}
    # stores
    req_vars::Dict{String, Set{Symbol}}
    req_lxdefs::Set{String}
    vars_aliases::Alias
    # notebooks
    nb_vars::VarsNotebook
    nb_code::CodeNotebook
    to_trigger::Set{String}
    # self
    page_hash::Ref{UInt64}
end


function GlobalContext(
            vars=Vars(),
            defs=LxDefs();
            alias=Alias()
        )

    parent_module(wipe=true)
    rpath = "__global__"
    # vars notebook
    mdl     = submodule(
                modulename("__global_vars", true);
                wipe=true,
                rpath
              )
    nb_vars = VarsNotebook(mdl)

    # utils notebook
    mdl     = submodule(
                modulename("__global_utils", true);
                wipe=true,
                rpath
              )
    nb_code = CodeNotebook(mdl)

    # rest
    anchors      = Dict{String, Anchor}()
    tags         = Dict{String, Tag}()
    paginated    = Set{String}()
    children     = Dict{String, LocalContext}()
    to_trigger   = Set{String}()
    init_trigger = Set{String}()
    deps_map     = DepsMap()

    gc = GlobalContext(
        vars,
        defs,
        alias,
        nb_vars,
        nb_code,
        anchors,
        tags,
        paginated,
        children,
        to_trigger,
        init_trigger,
        deps_map
    )

    set_current_global_context(gc)
    modules_setup(gc)
    return gc
end


# Note that when a local context is created it is automatically
# attached to its global context via the children_contexts
function LocalContext(glob, vars, defs, headings, rpath, alias=Alias())

    if isempty(rpath)
        error("LocalContext should be created with a non-empty rpath.")
    end

    # vars notebook
    mdl = submodule(
            modulename("$(rpath)_vars", true);
            wipe=true,
            # utils=true,
            rpath
    )
    nb_vars  = VarsNotebook(mdl)

    # code notebook
    mdl = submodule(
            modulename("$(rpath)_code", true);
            wipe=true,
            # utils=true,
            rpath
    )
    nb_code  = CodeNotebook(mdl)

    # req vars (keep track of what is requested by this page)
    req_vars = Dict{String, Set{Symbol}}(
        "__global__" => Set{Symbol}()
    )
    req_defs   = Set{String}()
    anchors    = Set{String}()
    to_trigger = Set{String}()
    page_hash  = Ref(UInt64(0))

    # form the object
    lc = LocalContext(
        glob,
        vars,
        defs,
        headings,
        rpath,
        anchors,
        Ref(false),    # is recursive
        Ref(false),    # is math
        req_vars,
        req_defs,
        alias,
        nb_vars,
        nb_code,
        to_trigger,
        page_hash
    )
    # attach it to global
    glob.children_contexts[rpath] = lc
    # *must* be done after attachment as depends on children context
    modules_setup(lc)
    return lc
end

function LocalContext(
            g=GlobalContext(),
            v=Vars(),
            d=LxDefs();
            rpath="",
            alias=Alias()
        )
    return LocalContext(g, v, d, PageHeadings(), rpath, alias)
end


Base.show(io::IO, gc::GlobalContext) = println(io, """
        GlobalContext
        -------------
        - $(length(gc.vars)) variables
        - $(length(gc.lxdefs)) lx definitions
        """)

Base.show(io::IO, lc::LocalContext) = println(io, """
        LocalContext ($(lc.rpath))
        ------------
        - $(length(lc.vars)) variables
        """)
