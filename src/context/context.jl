# Local context / page-wide

const PageVars = LittleDict{Symbol,Pair}
const LxDefs = LittleDict{String,LxDef}

struct Context
    pagevars::PageVars
    lxdefs::LxDefs
    is_recursive::Bool
    is_config::Bool
    is_maths::Bool
end
Context(pv, lxd) = Context(pv, lxd, false, false, false)
EmptyContext()   = Context(PageVars(), LxDefs())

recursify(c::Context) = Context(c.pagevars, c.lxdefs, true, c.is_config, c.is_maths)

mathify(c::Context) = Context(c.pagevars, c.lxdefs, c.is_recursive, c.is_config, true)
