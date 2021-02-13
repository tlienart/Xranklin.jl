"""
$(TYPEDEF)

Structure to keep track of the definition of a latex command declared via a
`\\newcommand{\\name}[narg]{def}` or of an environment via
`\\newenvironment{name}[narg]{pre}{post}`.
The parametric type depends on the definition type, for a command it will be
a SS, for an environment it will be a Pair of SS (pre and post).
"""
struct LxDef{T}
    name::String
    narg::Int
    def ::T
    # location of the definition
    from::Int
    to  ::Int
end
# if offset unspecified, start from basically -∞ (configs etc)
function LxDef(name::String, narg::Int, def)
    o = FRANKLIN_ENV[:OFFSET_LXDEFS] += 5  # precise offset doesn't matter
    LxDef(name, narg, def, o, o + 3)       # just forward a bit
end

from(lxd::LxDef) = lxd.from
to(lxd::LxDef)   = lxd.to

"""
pastdef(λ)

Convenience function to return a copy of a definition indicating as having
already been defined earlier in the context i.e.: earlier than any other
definition appearing in the current chunk.
"""
pastdef(λ::LxDef) = LxDef(λ.name, λ.narg, λ.def)


"""
$(TYPEDEF)

Super type for `LxCom` and `LxEnv`.
"""
abstract type LxObj <: FP.AbstractSpan end


"""
$(TYPEDEF)

A `LxCom` is a block with a definition and a vector of brace blocks. The type
depends on whether there is a definition (narg >= 1) or not. In the first case
it will be a `Ref{LxDef}`, and in the second, Nothing.
"""
struct LxCom{T} <: LxObj
    name  ::String
    ss    ::SS               # \\command
    lxdef ::T                # definition of the command
    braces::Vector{Block}    # relevant {...} with the command
end
LxCom(ss::SS, def) = LxCom(ss, def, Block[])


"""
$TYPEDEF

A `LxEnv` is similar to a `LxCom` but for an environment.

    `\\begin{aaa} ... \\end{aaa}`
    `\\begin{aaa}{opt1}{opt2} ... \\end{aaa}`
"""
struct LxEnv{T} <: LxObj
    name  ::String
    ss    ::SS
    lxdef ::T
    braces::Vector{Block}
    ocpair::Pair{Token,Token}
end
LxEnv(ss, def, ocp) = LxCom(ss, def, Block[], ocp)

"""
$SIGNATURES

Content of an `LxEnv` block.

    `\\begin{aaa}{opt1} XXX \end{aaa}` --> ` XXX `
"""
function content(lxe::LxEnv)::SS
    s = parent_string(lxe.ss)
    cfrom = nextind(s, to(lxe.ocpair.first))
    if !isempty(lxe.braces)
        cfrom = nextind(s, to(lxe.braces[end]))
    end
    cto = prevind(s, from(lxe.ocpair.second))
    return subs(s, cfrom, cto)
end
