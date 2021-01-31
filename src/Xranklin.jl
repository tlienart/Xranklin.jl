module Xranklin

import FranklinParser
import FranklinParser: subs, Block, SS, content
const FP = FranklinParser

import CommonMark
import CommonMark: disable!, enable!
const CM = CommonMark

using DocStringExtensions

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

include("convert/commonmark.jl")
include("convert/md2html.jl")
include("convert/md2latex.jl")
include("convert/html2html.jl")

include("convert/md_rules/basic.jl")

end # module
