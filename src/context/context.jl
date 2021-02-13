# Local context / page-wide

const PageVars = LittleDict{Symbol,Pair}

struct Context
    pagevars::PageVars
    lxdefs::Vector{LxDef}
end
EmptyContext() = Context(PageVars(), LxDef[])
