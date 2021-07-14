module Xranklin

import FranklinParser
const FP = FranklinParser
import FranklinParser: SS, Token, Block,
                       subs, content, dedent, parent_string,
                       from, to, previous_index, next_index

import CommonMark
const CM = CommonMark
import CommonMark: disable!, enable!, escape_xml

import OrderedCollections: LittleDict

# ------------------------------------------------------------------------

export html, latex

# ------------------------------------------------------------------------

const FRANKLIN_ENV = LittleDict{Symbol, Any}(
    :STRICT_PARSING => false,          # if true, fail on any parsing issue
    :SHOW_WARNINGS  => true,
    :OFFSET_LXDEFS  => -typemax(Int),  # helps keep track of order in lxcoms/envs
)

# ------------------------------------------------------------------------

include("context/latex/objects.jl")
include("context/context.jl")
include("context/default_context.jl")

include("convert/regex.jl")

include("convert/markdown/commonmark.jl")
include("convert/markdown/utils.jl")
include("convert/markdown/latex_objects.jl")
include("convert/markdown/to_html.jl")
include("convert/markdown/to_latex.jl")
include("convert/markdown/to_math.jl")

include("convert/markdown/rules/utils.jl")
include("convert/markdown/rules/text.jl")
include("convert/markdown/rules/headers.jl")
include("convert/markdown/rules/code.jl")
include("convert/markdown/rules/maths.jl")

end # module
