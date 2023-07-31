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
wiped. The reason for using `n = Module(:n)` is so that we don't get the msg
"WARNING: replacing module __XXX".
"""
newmodule(n::Symbol, p::Module)::Module =
    include_string(p, "$n = Module(:$n)")
newmodule(n::Symbol) = newmodule(n, parent_module())


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
    # we don't use newmodule here to avoid the WARNING: replacing module
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


const CORE_UTILS = [
    # reexports
    "cur_gc", "html", "html2", "latex",
    # base
    "cur_lc", "@lx_str", "path", "folderpath", "sitepath",
    "getlvar", "getgvar", "getvarfrom", "setlvar!", "setgvar!",
    # legacy access
    "locvar", "globvar", "pagevar",
    # tags, rpath
    "get_page_tags", "get_all_tags", "get_rpath",
    # attach, setproject
    "attach", "setproject!",
]


# DEV
function setup_var_module(gc::GlobalContext)
    F = env(:module_name) # Franklin/Xranklin

    #
    # Core module defines tools that can be used in Utils and which should
    # not be touched by the user.
    #
    core = """
        module $(env(:core_module_name))

        using $F
        export $(join(CORE_UTILS, ", "))

        macro lx_str(s)
            esc(
                quote
                    html(\$s, cur_gc())
                end
            )
        end

        path(s::Symbol)  = $F.path(cur_gc(), s)
        folderpath(p...) = joinpath(path(:folder), p...)
        sitepath(p...)   = joinpath(path(:site), p...)

        getlvar(n::Symbol, d=nothing; default=d) =
            $F.getvar(cur_lc(), cur_lc(), n, default)
        getgvar(n::Symbol, d=nothing; default=d) =
            $F.getvar(cur_gc(), cur_lc(), n, default)
        getvarfrom(n::Symbol, rpath::AbstractString, d=nothing; default=d) = begin
            rp = string(rpath)
            ks = keys(cur_gc().children_contexts)
            if (rp ∉ ks) && (rp * ".md" in ks)
                rp *= ".md"
            end
            return $F.getvar(
                cur_gc().children_contexts[rp], cur_lc(),
                n, default
            )
        end

        setlvar!(n::Symbol, v) = $F.setvar!(cur_lc(), n, v)
        setgvar!(n::Symbol, v) = $F.setvar!(cur_gc(), n, v)

        # legacy
        locvar(n, d=nothing; default=d)     = getlvar(Symbol(n); default)
        globvar(n, d=nothing; default=d)    = getgvar(Symbol(n); default)
        pagevar(s, n, d=nothing; default=d) = getvarfrom(Symbol(n), s; default)

        get_page_tags()   = $F.get_page_tags(cur_lc())
        get_page_tags(rp) = $F.get_page_tags(rp)
        get_all_tags()    = $F.get_all_tags(cur_gc())
        get_rpath()       = $F.get_rpath(cur_lc())

        attach(rp)        = $F.attach(cur_lc(), rp)

        setproject!(p::AbstractString) = $F.setproject!(cur_lc(), p)

        end # core module
        """

    utils = """
        module Utils

        using $F: @reexport
        @reexport import $F.Pkg
        @reexport import $F.Dates

        using ..$(env(:core_module_name))

        end

        using .Utils
        using .$(env(:core_module_name))
        """

    include_string(
        gc.nb_vars.mdl,
        core * utils
    )
end # setup_var_module(gc)

function get_utils_module(gc::GlobalContext)
    return gc.nb_vars.mdl.Utils
end
get_utils_module(lc::LocalContext) = get_utils_module(lc.glob)


function setup_var_module(lc::LocalContext)
    _setup_local_module(lc, lc.nb_vars.mdl)
    return
end

function setup_code_module(lc::LocalContext)
    mdl = submodule(
        modulename("$(lc.rpath)_code", true);
        wipe = true
    )
    _setup_local_module(lc, mdl)
    lc.nb_code.mdl = mdl
    return
end

function _setup_local_module(lc::LocalContext, mdl)
    # the reason for doing this weird path thing is because we're
    # instantiating modules as per `newmodule` which, for some reason, seems
    # to lose one level of nesting (but avoids the annoying "WARNING" message)
    utils_path = join([
        "$(parent_module())",
        replace(string(lc.glob.nb_vars.mdl), "Main." => ""),
        "Utils"],
        "."
    )
    core_path = replace(
        utils_path,
        r"\.Utils$" => ".$(env(:core_module_name))"
    )
    include_string(mdl, """
        using $core_path    # get_rpath, setlvar! etc
        using $utils_path   # user-defined utils
        """)
    return
end
