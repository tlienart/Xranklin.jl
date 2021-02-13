# Local context / page-wide

const PageVars = LittleDict{Symbol,Pair}

struct Context
    pagevars::PageVars
    lxdefs::Vector{LxDef}
end
const EmptyContext = Context(PageVars(), LxDef[])
