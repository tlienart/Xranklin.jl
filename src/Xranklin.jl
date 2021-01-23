module Xranklin

import FranklinParser: SS, Block, SubVector, Token, MD_IGNORE
# misc utils
import FranklinParser: subs, prepare_text
# block utils
import FranklinParser: content, get_classes
# partitioners
import FranklinParser: default_md_partition

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
