# Local context / page-wide

"""
    PageVars

Mapping `:varname => value`.

Legacy note: allowed types are not kept track of anymore. But when extracting values,
a default value can be specified and acts effectively as a type constraint.
"""
const PageVars = LittleDict{Symbol, Any}

"""
    PageHeaders

Mapping `header_id => (n_occurrence, level)` where `n_occurrence` indicates which
occurrence this header is of the same base anchor.
"""
const PageHeaders = LittleDict{String, NTuple{2, Int}}

"""
    LxDefs

Mapping `com_or_env_name => definition`.
"""
const LxDefs = LittleDict{String, LxDef}


"""
    Context

Typically instantiated at a page level, the context keeps track of the variables,
headers, definitions etc. to specify the context in which conversion is happening.

Fields:
-------
    vars: a dictionary of the current page variables.
    headers: a dictionary of the current page headers
    lxdefs: a dictionary of the currently available 'latex' definitions.
    is_recursive: whether we're in a recursive context.
    is_config: whether the page being analyzed is the config page.
    is_math: whether we're recursing in a math environment.
"""
mutable struct Context
    vars::PageVars
    headers::PageHeaders
    lxdefs::LxDefs
    is_recursive::Bool
    is_config::Bool
    is_math::Bool
end
Context(pv, h, lxd) = Context(pv, h, lxd, false, false, false)
EmptyContext()      = Context(PageVars(), PageHeaders(), LxDefs())

recursify(c::Context) = (c.is_recursive = true; c)
mathify(c::Context)   = (c.is_recursive = c.is_math = true; c)


"""
    value(c, name, default)

Retrieve the value stored in context `c` at key `name`. If the key doesn't exist, then
the default value is returned. Note that the type of the default value indicates the
expected type returned unless the default is set to nothing or equally if no default
value is given.
"""
function value(
            c::Context,
            n::Symbol,
            default::T=default_value(n)
            )::T where T
    n in keys(c.vars) && return c.vars[n]::T
    return default
end
value(c::Context, n::String, a...) = value(c, Symbol(n), a...)

# this is type unstable
value(c::Context, n::Symbol, default::Nothing) = get(c.vars, n, nothing)
