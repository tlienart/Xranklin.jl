module Xranklin

import FranklinParser
import FranklinParser: subs, Block, SS
const FP = FranklinParser

import CommonMark
import CommonMark: disable!, enable!
const CM = CommonMark

# ------------------------------------------------------------------------

export html

# ------------------------------------------------------------------------

# ==============================================
struct Context
    page_variables
    latex_definitions
end
const EmptyContext = Context(nothing, nothing)
# ==============================================

include("convert/md2html.jl")
include("convert/md2latex.jl")
include("convert/html2html.jl")

include("convert/rules/basic.jl")

end # module
