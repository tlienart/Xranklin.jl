const DefaultGlobalVars = Vars(
)
const DefaultGlobalLxDefs = LxDefs(
)


const DefaultLocalVars = Vars(
    # header
    :header_class      => "",
    :header_link       => true,
    :header_link_class => ""
)
const DefaultLocalLxDefs = LxDefs()


##############################################################################

DefaultGlobalContext() = GlobalContext(
    DefaultGlobalVars,
    DefaultGlobalLxDefs
)

DefaultLocalContext(g=DefaultGlobalContext()) = LocalContext(
    g,
    DefaultLocalVars,
    DefaultLocalLxDefs,
)
