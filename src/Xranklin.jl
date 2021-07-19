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
import Dates

# ------------------------------------------------------------------------

export value, valuefrom
export html, latex

# legacy
export locvar, globvar, pagevar

# ------------------------------------------------------------------------

const MODULE_NAME = "Xranklin"

const FRANKLIN_ENV = LittleDict{Symbol, Any}(
    :STRICT_PARSING => false,          # if true, fail on any parsing issue
    :SHOW_WARNINGS  => true,
    :OFFSET_LXDEFS  => -typemax(Int),  # helps keep track of order in lxcoms/envs
    :CUR_LOCAL_CTX  => nothing,        # current local context
)

# ------------------------------------------------------------------------

include("misc_utils.jl")

include("context/types.jl")
include("context/context.jl")
include("context/default_context.jl")

include("convert/regex.jl")

include("convert/markdown/commonmark.jl")
include("convert/markdown/utils.jl")
include("convert/markdown/latex_objects.jl")
include("convert/markdown/to_html.jl")
include("convert/markdown/to_latex.jl")
include("convert/markdown/to_math.jl")

include("convert/markdown/code/utils.jl")
include("convert/markdown/code/run.jl")

include("convert/markdown/rules/utils.jl")
include("convert/markdown/rules/text.jl")
include("convert/markdown/rules/headers.jl")
include("convert/markdown/rules/code.jl")
include("convert/markdown/rules/maths.jl")
include("convert/markdown/rules/vars.jl")

end # module
