const DefaultLocalPageVars = PageVars(
    # header
    :header_class      => "",
    :header_link       => true,
    :header_link_class => ""
)

default_value(n::Symbol) = get(DefaultLocalPageVars, n, nothing)

DefaultContext() = Context(copy(DefaultLocalPageVars), PageHeaders(), LxDefs())
