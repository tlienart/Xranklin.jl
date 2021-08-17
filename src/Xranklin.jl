module Xranklin

# ------------------------------------------------------------------------
# stdlib

import Dates
import Base.(/)
import REPL: softscope
import Pkg
import Serialization: serialize, deserialize

# ------------------------------------------------------------------------
# external

import FranklinParser
const FP = FranklinParser
import FranklinParser: SS, Token, Block,
                       subs, content, dedent, parent_string,
                       from, to, previous_index, next_index

import FranklinTemplates: newsite, filecmp
import LiveServer

# ------------------------------------------------------------------------
# External Dependencies

import CommonMark
import CommonMark: disable!, enable!, escape_xml
const CM = CommonMark

import IOCapture
import JSON3
import OrderedCollections: LittleDict

# ------------------------------------------------------------------------

export serve
export newsite

# Conversion functions
export html, latex

# Access contexts
export getvar, getvarfrom, getlvar, getgvar, setlvar!, setgvar!
export locvar, globvar, pagevar  # LEGACY

# ------------------------------------------------------------------------

const FRANKLIN_ENV = LittleDict{Symbol, Any}(
    :module_name       => "Xranklin",     # TODO: remove here and in newmodule
    :strict_parsing    => false,          # if true, fail on any parsing issue
    :offset_lxdefs     => -typemax(Int),  # helps keep track of order in lxcoms/envs
    :cur_global_ctx    => nothing,        # current global context
    :cur_local_ctx     => nothing,        # current local context
)
env(s::Symbol)       = FRANKLIN_ENV[s]
setenv(s::Symbol, v) = (FRANKLIN_ENV[s] = v; nothing)

# ------------------------------------------------------------------------

include("misc_utils.jl")

# ------------------------------------------------------------------------

# the ordering here is a bit awkard but we want contexts to point
# to 'Notebook' objects which are tied to code environment.

include("context/types.jl")
include("context/context.jl")
include("context/default_context.jl")

include("context/code/modules.jl")
include("context/code/notebook.jl")
include("context/code/serialize.jl")
include("context/code/notebook_vars.jl")
include("context/code/notebook_code.jl")

# ------------------------------------------------------------------------

include("convert/regex.jl")

# ===> MARKDOWN

include("convert/markdown/commonmark.jl")
include("convert/markdown/utils.jl")

# LxFuns
include("convert/markdown/lxfuns/utils.jl")
include("convert/markdown/lxfuns/hyperrefs.jl")

include("convert/markdown/latex_objects.jl")

include("convert/markdown/to_html.jl")
include("convert/markdown/to_latex.jl")
include("convert/markdown/to_math.jl")

include("convert/markdown/rules/utils.jl")
include("convert/markdown/rules/text.jl")
include("convert/markdown/rules/headers.jl")
include("convert/markdown/rules/code.jl")
include("convert/markdown/rules/maths.jl")

# ===> POSTPROCESSING

include("convert/postprocess/hfuns/utils.jl")
include("convert/postprocess/hfuns/input.jl")
include("convert/postprocess/hfuns/hyperrefs.jl")

include("convert/postprocess/utils.jl")
include("convert/postprocess/html2.jl")
include("convert/postprocess/latex2.jl")

# ------------------------------------------------------------------------

include("build/paths.jl")
include("build/watch.jl")
include("build/process.jl")
include("build/serve.jl")

end # module
