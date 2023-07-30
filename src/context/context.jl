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
                        it's also the notebook that contains FranklinCore and
                        Utils that other pages can call upon.
    anchors           : dictionary of all anchors {id => Anchor}
    tags              : dictionary of all tags {id => Tag}
    paginated         : set of pages `{rpath}` which are paginated
    children_contexts : associated local contexts {rpath => lc}
    req_vars          : mapping {pg => set of vars requested from GC}
    req_lxdefs        : mapping {pg => set of lxdefs requested from GC}
    deps_map          : data structure keeping track of what markdown pages
                         depends on what files (e.g. literate scripts) and vice
                         versa, to check whether a page needs to be updated.
"""
struct GlobalContext{LC<:Context} <: Context
    vars::Vars
    lxdefs::LxDefs
    vars_aliases::Alias
    nb_vars::VarsNotebook
    anchors::Dict{String, Anchor}
    tags::Dict{String, Tag}
    paginated::Set{String}
    children_contexts::Dict{String, LC}
    req_vars::Dict{String, Set{Symbol}}
    req_lxdefs::Dict{String, Set{String}}
    deps_map::DepsMap
end


"""
    LocalContext

Typically instantiated at a page level, the context keeps track of the
variables, headings, definitions etc. to specify the context in which the
conversion is happening.

## Fields

    glob          : the parent context
    vars          : a dictionary of the local variables
    vars_aliases  : other accepted names for default variables
    lxdefs        : a dictionary of the local lx-definitions
    headings      : a dictionary of the current page headings
    rpath         : relative path to the page with this local context
                     this includes the extension so e.g. foo/bar/baz.md.
                     It is system dependent (so not necessarily unix).
    anchors       : set of anchor ids defined on the page
    is_recursive  : whether we're in a recursive context
    is_math       : whether we're recursing in a math environment
    req_vars      : mapping {pg => set of vars requested from pg}
    nb_vars       : notebook associated with markdown defs
    nb_code       : notebook associated with the page code
    to_trigger    : set of dependent pages to trigger after updating LC

### Notes on `req_lxdefs`

This field is a dictionary of lxdefs requested from the global context.

### Notes on `req_vars`

The purpose of `req_vars` is to keep track of cross-context symbol requests.

There are two scenarios:

TODO UPDATE THIS


1. The current local context requests something from its global context,
    in that case there's a special entry `"__global__" => set_of_global_symbols`
2. Another context requests something from the current context, in that case
    there's an entry `"path_of_requester" => set_of_requested_symbols`.

**Example for (1)**:
    Page `A.md` fills a variable `gg` from global context (e.g. via `{{gg}}`),
    then `req_vars` of `A.md` will necessarily have an entry
    `"__global__" => set` with `:gg` in set.

**Example for (2)**:
    Page `B.md` fills a variable `aa` from page `A.md` (e.g. via
    `{{fill aa A.md}}`) then the `req_vars` of `A.md` will necessarily have an
    entry `"B.md" => set_of_symbols`
where `:aa` is now in the `set_of_symbols`.

If `B.md` is triggered, all pages which may have a `B.md` entry, lose that entry
(and if `B.md` still makes a request from them, that entry will be re-added).
"""
struct LocalContext <: Context
    glob::GlobalContext
    vars::Vars
    vars_aliases::Alias
    lxdefs::LxDefs
    headings::PageHeadings
    rpath::String
    anchors::Set{String}
    # chars
    is_recursive::Ref{Bool}
    is_math::Ref{Bool}
    # stores
    req_vars::Dict{String, Set{Symbol}}
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
    # vars notebook
    mdl = submodule(
        modulename("__global_vars", true);
        wipe=true
    )
    nb_vars = VarsNotebook(mdl)

    # rest
    anchors      = Dict{String, Anchor}()
    tags         = Dict{String, Tag}()
    paginated    = Set{String}()
    children     = Dict{String, LocalContext}()
    req_vars     = Dict{String, Set{Symbol}}()
    req_lxdefs   = Dict{String, Set{String}}()
    deps_map     = DepsMap()

    gc = GlobalContext(
        vars,
        defs,
        alias,
        nb_vars,
        anchors,
        tags,
        paginated,
        children,
        req_vars,
        req_lxdefs,
        deps_map
    )

    set_current_global_context(gc)
    setup_var_module(gc)
    return gc
end


# Note that when a local context is created it is automatically
# attached to its global context via the children_contexts
function LocalContext(
            glob, vars, defs, headings, rpath, alias=Alias()
        )

    if isempty(rpath)
        error("LocalContext should be created with a non-empty rpath.")
    end

    # vars notebook
    mdl = submodule(
            modulename("$(rpath)_vars", true);
            wipe=true
    )
    nb_vars  = VarsNotebook(mdl)
    # code notebook (initialise with dummy module until some code-to-execute
    # is encountered in which case `setup_code_module` is called
    # (see code/modules.jl)
    nb_code  = CodeNotebook()

    # req vars (keep track of what is requested from this page)
    req_vars   = Dict{String, Set{Symbol}}()
    anchors    = Set{String}()
    to_trigger = Set{String}()
    page_hash  = Ref(UInt64(0))

    # form the object
    lc = LocalContext(
        glob,
        vars,
        alias,
        defs,
        headings,
        rpath,
        anchors,
        Ref(false),    # is recursive
        Ref(false),    # is math
        req_vars,
        nb_vars,
        nb_code,
        to_trigger,
        page_hash
    )
    # attach it to global
    glob.children_contexts[rpath] = lc
    # *must* be done after attachment as depends on children context
    # for the setup of the code module, see comment earlier at instantiation
    # of nb_code.
    set_current_local_context(lc)
    setup_var_module(lc)
    return lc
end

function LocalContext(
            g=GlobalContext(),
            v=Vars(),
            d=LxDefs();
            rpath="",
            alias=Alias()
        )
    return LocalContext(
        g, v, d, PageHeadings(), rpath, alias
    )
end


Base.show(io::IO, gc::GlobalContext) = println(io, """
        GlobalContext
        -------------
        - $(length(gc.vars)) variable(s)
        - $(length(gc.lxdefs)) lx definition(s)
        - $(length(gc.children_contexts)) children context(s)
        """)

Base.show(io::IO, lc::LocalContext) = println(io, """
        LocalContext (rpath: '$(lc.rpath)')
        ------------
        - $(length(lc.vars)) variable(s)
        """)
