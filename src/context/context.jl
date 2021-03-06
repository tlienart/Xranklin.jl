# Local context / page-wide

const PageVars = LittleDict{Symbol,Pair}
const LxDefs = LittleDict{String,LxDef}

mutable struct Context
    pagevars::PageVars
    lxdefs::LxDefs
    is_recursive::Bool
    is_config::Bool
    is_math::Bool
end
Context(pv, lxd) = Context(pv, lxd, false, false, false)
EmptyContext()   = Context(PageVars(), LxDefs())

recursify(c::Context) = (c.is_recursive = true; c)

mathify(c::Context) = (c.is_recursive = c.is_math = true; c)
