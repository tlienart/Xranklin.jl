module Xranklin

# ------------------------------------------------------------------------
# stdlib

import Dates
import Base.(/)
import REPL: softscope
import Pkg
import Serialization: serialize, deserialize

# ------------------------------------------------------------------------
# external dependencies part of the Franklin universe

import FranklinParser
const FP = FranklinParser
import FranklinParser: SS, Token, Block, Group,
                       subs, content, dedent, parent_string,
                       from, to, prev_index, next_index


import FranklinTemplates: newsite, filecmp
import LiveServer

# ------------------------------------------------------------------------
# external dependencies not part of the Franklin universe

import URIs
import IOCapture
import JSON3
import OrderedCollections: LittleDict

# copied from CommonMark.jl, used in dealing with autolink
@inline issafe(c::Char) = c in "?:/,-+@._()#=*&%" ||
                          (isascii(c) && (isletter(c) || isnumeric(c)))
normalize_uri(s::SS)    = URIs.escapeuri(s, issafe)

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
    :module_name       => "Xranklin",     # TODO: remove here, in newmodule, in delay
    :strict_parsing    => false,          # if true, fail on any parsing issue
    :offset_lxdefs     => -typemax(Int),  # helps keep track of order in lxcoms/envs
    :cur_global_ctx    => nothing,        # current global context
    :cur_local_ctx     => nothing,        # current local context
)
env(s::Symbol)       = FRANKLIN_ENV[s]
setenv(s::Symbol, v) = (FRANKLIN_ENV[s] = v; nothing)

# see 'macro delay'
const DELAYED_PAGES = Set{String}()

# ------------------------------------------------------------------------

include("misc_utils.jl")
include("html_utils.jl")

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

# >> LxFuns
include("convert/markdown/lxfuns/utils.jl")
include("convert/markdown/lxfuns/hyperrefs.jl")

# >> LxObjects
include("convert/markdown/latex_objects.jl")

# >> Core
include("convert/markdown/md_core.jl")

# >> Rules
include("convert/markdown/rules/utils.jl")
include("convert/markdown/rules/text.jl")
include("convert/markdown/rules/list.jl")
# include("convert/markdown/rules/table.jl")
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
