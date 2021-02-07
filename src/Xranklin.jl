module Xranklin

import FranklinParser
import FranklinParser: subs, Block, SS, content, previous_index, next_index
const FP = FranklinParser

import CommonMark
import CommonMark: disable!, enable!
const CM = CommonMark

using DocStringExtensions

# ------------------------------------------------------------------------

export html, latex

# ------------------------------------------------------------------------

# ==============================================
struct Context
    page_variables
    latex_definitions
end
const EmptyContext = Context(nothing, nothing)
# ==============================================

include("convert/markdown/commonmark.jl")
include("convert/markdown/utils.jl")
include("convert/markdown/to_html.jl")
include("convert/markdown/to_latex.jl")

include("convert/markdown/rules/basic.jl")
include("convert/markdown/rules/code.jl")

end # module
