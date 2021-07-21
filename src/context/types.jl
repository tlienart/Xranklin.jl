"""
    SetDict

Bidirectional dictionary to help keep track of relations where we need to both
be able to get `value => set_of_requesters` and `requester => set_of_values`.
"""
struct SetDict{A, B}
    fwd::LittleDict{A, Set{B}}
    bwd::LittleDict{B, Set{A}}
end
SetDict{A, B}() where {A, B} = SetDict(
    LittleDict{A, Set{B}}(),
    LittleDict{B, Set{A}}()
)

"""
    add!(sd, k, v)

Add the forward relation `k => v` and the backward relation `v => k`.
"""
function add!(sd::SetDict{A, B}, k::A, v::B) where {A, B}
    if k in keys(sd.fwd)
        union!(sd.fwd[k], [v])
    else
        sd.fwd[k] = Set{B}([v])
    end
    if v in keys(sd.bwd)
        union!(sd.bwd[v], [k])
    else
        sd.bwd[v] = Set{A}([k])
    end
    return
end


# ============================================================================
"""
    Vars

Mapping `:varname => value`.

Legacy note: allowed types are not kept track of anymore. But when extracting
values via `value(...)` a default value can be specified and effectively acts
as a type constraint.
"""
const Vars = LittleDict{Symbol, Any}


"""
    VarsDeps

Bidirectional mapping `:varname => [pages using]`.
"""
const VarsDeps = SetDict{Symbol, String}


"""
    value(...)

Get the value of a variable with default if there's no page variable of that
name in the context.

Type stable: when an explicit default is given, the value returned is
         constrained to that type.
Type unstable: when no explicit default is given (or is nothing), the value
         returned is unconstrained.
"""
value(v::Vars, name::Symbol, default::T) where T = get(v, name, default)::T
value(v::Vars, name::Symbol, d::Nothing=nothing) = get(v, name, nothing)


"""
    setvar!(...)

Set the value of a variable (overwriting existing one if any).
"""
setvar!(v::Vars, name::Symbol, val) = (v[name] = val; nothing)


# ============================================================================
"""
    LxDef{T}

Structure to keep track of the definition of a latex-like command declared via
something like

    `\\newcommand{\\name}[nargs]{def}`

or of a latex-like environment declared via something like

    `\\newenvironment{name}[nargs]{pre}{post}`

The parametric type depends on the definition type. For a command it will be
a String, for an environment it will be a Pair of String (pre and post).
"""
struct LxDef{T}
    nargs::Int
    def::T
    # location of the definition
    from::Int
    to::Int
end
# if offset unspecified, start from basically -∞ (configs etc)
function LxDef(nargs::Int, def)
    o = FRANKLIN_ENV[:offset_lxdefs] += 5  # precise offset doesn't matter
    LxDef(nargs, def, o, o + 3)            # just forward a bit
end

from(lxd::LxDef) = lxd.from
to(lxd::LxDef)   = lxd.to


"""
    pastdef(λ)

Convenience function to return a copy of a definition indicated as having
already been defined earlier in the context i.e.: earlier than any other
definition appearing in the current chunk.
"""
pastdef(λ::LxDef) = LxDef(λ.nargs, λ.def)


"""
    LxDefs

Mapping `lx_name => definition`.
"""
const LxDefs = LittleDict{String, LxDef}


"""
    LxDefsDeps

Bidirectional mapping `com_or_env_name <=> [pages using]`.
"""
const LxDefsDeps = SetDict{String, String}


"""
    setdef!(ld, n, d)

Set a latex definition.
"""
setdef!(ld::LxDefs, n::String, d::LxDef) = (ld[n] = d; nothing)


"""
    hasdef(...)

Indicate whether a definition is available, boolean returned.

Note: there's a separation between hasdef and getdef so that getdef
can be guaranteed to return an LxDef.
"""
hasdef(d::LxDefs, n::String)::Bool = n in keys(d)


"""
    getdef(...)

Return the definition associated with a name. This expects the name
to be present.
"""
getdef(d::LxDefs, n::String)::LxDef = d[n]


# ============================================================================
"""
    PageHeaders

Mapping `header_id => (n_occurrence, level)` where `n_occurrence` indicates
which occurrence this header is of the same base anchor.
"""
const PageHeaders = LittleDict{String, NTuple{2, Int}}
