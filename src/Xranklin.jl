module Xranklin

import FranklinParser
const FP = FranklinParser
import FranklinParser: SS, Token, Block,
                       subs, content, dedent,
                       from, to, previous_index, next_index

import CommonMark
const CM = CommonMark
import CommonMark: disable!, enable!

import OrderedCollections: LittleDict

using DocStringExtensions

# ------------------------------------------------------------------------

export html, latex

# ------------------------------------------------------------------------

include("environment.jl")

include("context/latex/objects.jl")
include("context/context.jl")

include("convert/regex.jl")

include("convert/markdown/commonmark.jl")
include("convert/markdown/utils.jl")
include("convert/markdown/assemble_latex_objects.jl")
include("convert/markdown/to_html.jl")
include("convert/markdown/to_latex.jl")

include("convert/markdown/rules/text.jl")
include("convert/markdown/rules/code.jl")
include("convert/markdown/rules/maths.jl")
include("convert/markdown/rules/latex.jl")

end # module
