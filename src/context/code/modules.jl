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
            wipe::Bool=false,
            utils::Bool=false,
            rpath::String=""
        )::Module

    p = parent_module()
    if !wipe && ismodule(n, p)
        m = getfield(p, n)
    else
        m = newmodule(n, p)
    end
    utils && using_utils!(m)
    return m
end


"""
    using_utils!(m)

Import (Using) the current utils module in `m`. See `LocalContext` instantiation
with each of its notebooks bringing utils in.
"""
function using_utils!(m::Module)
    gc = env(:cur_global_ctx)
    isnothing(gc) && return
    utils_mdl = gc.nb_code.mdl
    s = replace(
        "import $(parent_module()).$(utils_mdl) as Utils",
        ".Main." => "."
    )
    include_string(softscope, m, s)
    return
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
    modules_setup(m)

Setup the module with getvar etc.
"""
modules_setup(c::Context) = begin
    F = env(:module_name)
    rpath = c isa GlobalContext ? "__global__" : c.rpath
    for m in (c.nb_vars.mdl, c.nb_code.mdl)
        include_string(m, """
            using $F
            const __gc = cur_gc()
            const __lc = get(__gc.children_contexts, "$rpath", nothing)

            getlvar(n::Symbol, d=nothing; default=d) =
                getvar(__lc, __lc, n, default)
            getgvar(n::Symbol, d=nothing; default=d) =
                getvar(__gc, __lc, n, default)
            getvarfrom(n::Symbol, rpath::String, d=nothing; default=d) =
                getvar(__gc.children_contexts[rpath], __lc, n, default)

            setlvar!(n::Symbol, v) = setvar!(__lc, n, v)
            setgvar!(n::Symbol, v) = setvar!(__gc, n, v)

            # legacy commands
            locvar(n, d=nothing; default=d)     = getlvar(Symbol(n); default)
            globvar(n, d=nothing; default=d)    = getgvar(Symbol(n); default)
            pagevar(s, n, d=nothing; default=d) = getvarfrom(Symbol(n), s; default)

            get_page_tags() = get_page_tags(__lc)
            get_rpath()     = isnothing(__lc) ? "" : __lc.rpath
            """
        )
    end
    return
end
