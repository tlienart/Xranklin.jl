# function GenerateDefaultGlobalLxDefs()
#     LxDefs()
# end
# function DefaultGlobalLxDefs()
#     LxDefs(
#         # Commands
#         "eqref" => LxDef
#
#         # Environments
#         "equation" => LxDef(0, raw"\[" => raw"\]"),
#         "align"    => LxDef(0, raw"\[\begin{aligned}"    => raw"\end{aligned}\]"),
#         "aligned"  => LxDef(0, raw"\[\begin{aligned}"    => raw"\end{aligned}\]"),
#         "eqnarray" => LxDef(0, raw"\[\begin{array}{rcl}" => raw"\end{array}\]"  ),
#     )
# end

const INTERNAL_LXFUNS = [
    :toc, :tableofcontents,
    # :eqref,
    # :cite, :citet, :citep,
    # :label, :biblabel,
    # :toc,
    # :reflink,
    # ...
]

# """
#     \failed{...}
#
# LxFun used for when other lxfuns fail.
# """
