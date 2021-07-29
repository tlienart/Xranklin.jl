"""
    modulename(id, h)

Return a standardised module name either with the given id or with a short
hash of the given id if `h=true`.
"""
function modulename(id::String, h::Bool=false)::Symbol
    p = uppercase(ifelse(h, first(string(hash(id)), 7), id))
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
function parent_module(; wipe::Bool=false)::Module
    n = modulename("parent")
    !wipe && ismodule(n) && return getfield(Main, n)
    return newmodule(n, Main)
end


"""
    submodule(n)

Either return the a submodule with name `n` if it exists as a child of the
parent module or create a new one and return it.
"""
function submodule(n::Symbol; wipe::Bool=false)
    p = parent_module()
    !wipe && ismodule(n, p) && return getfield(p, n)
    return newmodule(n, p)
end


const UTILS_MODULE_NAME = modulename("utils")
const VARS_MODULE_NAME  = modulename("vars")

vars_module(; wipe=false)          = submodule(VARS_MODULE_NAME;  wipe=wipe)
utils_module(; wipe=false)         = submodule(UTILS_MODULE_NAME; wipe=wipe)
page_module(p::String; wipe=false) = submodule(modulename(p, true); wipe=wipe)
