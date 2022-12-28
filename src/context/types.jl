"""
    Vars

Mapping `:varname => value`.

[Legacy note] allowed types are not kept track of anymore. But when extracting
values via `getvar(...)` a default value can be specified and effectively acts
as a type constraint.
"""
const Vars = Dict{Symbol, Any}


"""
    getvar(...)

Get the value of a variable with default if there's no page variable of that
name in the context.

Type stable: when an explicit default is given, the value returned is
         constrained to that type.
Type unstable: when no explicit default is given (or is nothing), the value
         returned is unconstrained.
"""
getvar(v::Vars, name::Symbol, default::T) where T = T(get(v, name, default))
getvar(v::Vars, name::Symbol, d::Nothing=nothing) = get(v, name, nothing)


"""
    setvar!(...)

Set the value of a variable (overwriting existing one if any).
"""
setvar!(v::Vars, name::Symbol, val) = (v[name] = val; nothing)


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
const LxDefs = Dict{String, LxDef}


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
    PageHeadings

Mapping `heading_id => (n_occurrence, level, text)` where `n_occurrence`
indicates which occurrence this heading is of the same base anchor, `level`
is the heading level and `text` is the current text representation of the
title. For instance when converting to HTML,

    `### Foo **bar**`

will given an entry

    `foo_bar => (1, 3, "Foo <strong>bar</strong>")

DEV: we must use a little dict here to guarantee order.
"""
const PageHeadings = LittleDict{
    String,
    Tuple{Int, Int, String}
}


"""
    PageRefs

Mapping `anchor => target`.
"""
const PageRefs = Dict{
    String,  # e.g. from '[the link]' to 'the_link'
    String   # e.g. 'https://example.com' or '#the_note'
}


"""
    Anchor

See anchors.jl, eltype of one of the fields of GC.

## Fields

    * id   : the id of the anchor (e.g.: 'foo_bar')
    * locs : list of rpaths that define the anchor, the last one is the one
              that gets used.
    * reqs : set of rpaths that require the anchor.
"""
struct Anchor
    id::String
    locs::Vector{String}
    reqs::Set{String}
end

Anchor(id::String, loc::String) = Anchor(id, [loc], Set{String}())


"""
    Tag

See tags.jl, eltype of one of the fields of GC.

## Fields

    * id   : the id of the tag (e.g.: 'foo_bar')
    * name : full tag name (e.g. "Foo Bar")
    * locs : set of rpaths that indicate this tag.
"""
struct Tag
    id::String
    name::String
    locs::Set{String}
end

Tag(id::String, name::String, loc::String) = Tag(id, name, Set([loc]))
