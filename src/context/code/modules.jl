#
# General structure (replicated for vars / code)
#
#   module Page
#       module FranklinCore
#           using Reexport
#           export cur_gc, ...
#           cur_gc = ...
#       end
#
#       module Utils
#           using Reexport
#           using ..FranklinCore
#       end
#
#       using .FranklinCore
#       using .Utils
#   end
#
# if a user wants to make a module available in a 'using' way to all cells
# they should just do `@reexport using Dates` in `utils.jl`.
#
#   See test/indir/utils.jl
#
#


"""
    modulename(id, h)

Return a standardised module name either with the given id or with a short
hash of the given id if `h=true`.
"""
function modulename(
            id::String,
            h::Bool=false
        )::Symbol

    p = ifelse(
            h,
            first(string(hash(id)), 7),
            id
        ) |> uppercase
    return Symbol("__FRANKLIN_$(p)")
end

"""
    ismodule(n, p)

Checks whether a name is an existing module or submodule of `p`.
"""
function ismodule(n::Symbol, p::Module=Main)::Bool
    return isdefined(p, n) && typeof(getfield(p, n)) == Module
end

"""
    newmodule(n, p)

Create a new module with name `n` and parent `p`. If the module exists, it is
wiped.
"""
newmodule(n::Symbol, p::Module=parent_module())::Module =
    include_string(p, "$n = Module(:$n); $n")


"""
    parent_module(; wipe=false)

Either return the parent module if it exists or create one and return it.
The parent module is attached to `Main`. All other modules created within
the context of a Franklin session are attached to it.

The reasoning is that if everything was attached to Main then these modules
would outlive the session. Here we can make sure that the parent module gets
wiped at the end of a session meaning which will leave us with only one, empty
module in Main.

:Main
    :__FRANKLIN_PARENT
        :__FRANKLIN_UTILS
        :__FRANKLIN_VARS
        :__FRANKLIN_...
        :__FRANKLIN_...
"""
function parent_module(;
            wipe::Bool=false
         )::Module

    n = modulename("parent")
    if !wipe && ismodule(n)
        return getfield(Main, n)
    end
    return newmodule(n, Main)
end


"""
    submodule(n)

Either return the a submodule with name `n` if it exists as a child of the
parent module or create a new one and return it.
"""
function submodule(
            n::Symbol;
            wipe::Bool=false
        )::Module

    p = parent_module()
    if !wipe && ismodule(n, p)
        m = getfield(p, n)
    else
        m = newmodule(n, p)
    end
    return m
end


"""
    parse_code(code)

Consumes a string with Julia code, returns a vector of expression(s).
"""
function parse_code(code::String)
    exs  = Any[]             # Expr, Symbol or Any Julia core value
    n    = sizeof(code)
    pos  = 1
    while pos ≤ n
        ex, pos = Meta.parse(code, pos)
        isnothing(ex) && continue
        push!(exs, ex)
    end
    exs
end


"""
    UTILS_UTILS

Names of core functionalities imported in all nb_vars and nb_code modules.
These are specific to the environment, so for instance the `__lc` is
associated with the page to which the notebooks are attached.
"""
const UTILS_UTILS = [
    # from module
    "cur_gc", "html", "latex", "html2", "@lx_str",
    # others
    "__gc", "__lc", "attach",
    "cur_lc", "path", "folderpath", "sitepath",
    "getlvar", "getgvar", "getvarfrom",
    "setlvar!", "setgvar!",
    "locvar", "globvar", "pagevar",
    "get_page_tags", "get_all_tags", "get_rpath",
    # project
    "setproject!"
]


"""
    utils_code(gc; crop)

Utils module within the default code imported in all `nb_vars` and `nb_code`
modules.
The code in the `Utils` module is that of `gc.vars[:_utils_code]` which is
set by `process_utils` via reading the `utils.jl` file.

The important bit here is to note that if a function in `utils.jl` calls
something like `getvarfrom`, it is the `getvarfrom` of the specific
module (with a specific `__lc`) that will be called in that function so
that the page requesting the variable can be adequately tracked.
"""
function utils_code(gc::GlobalContext; glob=false, crop=false)
    body = """
        using ..$(env(:core_module_name))
        $(get(gc.vars, :_utils_code, ""))
        """
    # useful for process_utils
    crop && return body
    # otherwise
    F = env(:module_name)
    return """
    module Utils
        using $F: @reexport
        $(ifelse(glob, "", body))
    end
    using .Utils
    """
end

"""
    modules_setup(c)

Setup the module with getvar etc.
"""
modules_setup(c::Context) = begin
    F     = env(:module_name)
    rpath = get_rpath(c)
    gc    = get_glob(c)
    glob  = (c === gc)

    exp_names = join((u for u in UTILS_UTILS if u ∉ ("__gc", "__lc")), ",")


    for m in (c.nb_vars.mdl, c.nb_code.mdl)
        base_code = """
            module $(env(:core_module_name))

            export $exp_names

            using $F
            using $F: @reexport

            @reexport import Pkg
            @reexport import Dates

            const __gc = cur_gc()
            const __lc = get(__gc.children_contexts, "$rpath", nothing)

            cur_lc()         = __lc
            path(s::Symbol)  = $F.path(__gc, s)
            folderpath(p...) = joinpath(path(:folder), p...)
            sitepath(p...)   = joinpath(path(:site), p...)

            macro lx_str(s)
                esc(
                    quote
                        html(\$s, cur_gc())
                    end
                )
            end

            getlvar(n::Symbol, d=nothing; default=d) =
                $F.getvar(__lc, __lc, n, default)
            getgvar(n::Symbol, d=nothing; default=d) =
                $F.getvar(__gc, __lc, n, default)
            getvarfrom(n::Symbol, rpath::AbstractString, d=nothing; default=d) = begin
                rp = string(rpath)
                ks = keys(__gc.children_contexts)
                if (rp ∉ ks) && (rp * ".md" in ks)
                    rp *= ".md"
                end
                return $F.getvar(__gc.children_contexts[rp], __lc, n, default)
            end

            setlvar!(n::Symbol, v) = $F.setvar!(__lc, n, v)
            setgvar!(n::Symbol, v) = $F.setvar!(__gc, n, v)

            # legacy commands
            locvar(n, d=nothing; default=d)     = getlvar(Symbol(n); default)
            globvar(n, d=nothing; default=d)    = getgvar(Symbol(n); default)
            pagevar(s, n, d=nothing; default=d) = getvarfrom(Symbol(n), s; default)

            get_page_tags()   = $F.get_page_tags(__lc)
            get_page_tags(rp) = $F.get_page_tags(rp)
            get_all_tags()    = $F.get_all_tags(__gc)
            get_rpath()       = $F.get_rpath(__lc)

            attach(rp)        = $F.attach(__lc, rp)

            setproject!(p::AbstractString) = $F.setproject!(__lc, p)

            end # core module
            """
        
        # make all the core names that are exported available in the
        # notebook module
        base_code *= """
            using .$(env(:core_module_name))
            """

        include_string(m, base_code * utils_code(gc; glob))
    end
    return
end

utils_module(c::Context) = c.nb_code.mdl.Utils
