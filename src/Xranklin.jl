module Xranklin

import FranklinParser: SS, Block, SubVector, Token, MD_IGNORE
# misc utils
import FranklinParser: subs, prepare
# block utils
import FranklinParser: content, get_classes
# partitioners
import FranklinParser: default_md_partition

import CommonMark

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
include("convert/md2html_rules/text.jl")
include("convert/md2html_rules/basic.jl")

end # module
