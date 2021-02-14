"""
    LxDef{T}

Structure to keep track of the definition of a latex command declared via a
`\\newcommand{\\name}[nargs]{def}` or of an environment via
`\\newenvironment{name}[nargs]{pre}{post}`.
The parametric type depends on the definition type, for a command it will be
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
    o = FRANKLIN_ENV[:OFFSET_LXDEFS] += 5  # precise offset doesn't matter
    LxDef(nargs, def, o, o + 3)       # just forward a bit
end

from(lxd::LxDef) = lxd.from
to(lxd::LxDef)   = lxd.to

"""
pastdef(λ)

Convenience function to return a copy of a definition indicating as having
already been defined earlier in the context i.e.: earlier than any other
definition appearing in the current chunk.
"""
pastdef(λ::LxDef) = LxDef(λ.nargs, λ.def)
