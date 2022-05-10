module Xranklin

# ------------------------------------------------------------------------
# stdlib

import Dates
import Dates: Date
import Base.(/)
import REPL: softscope
import Pkg
import Serialization: serialize, deserialize
import Logging
import TOML
import CRC32c: crc32c
import Base: push!, delete!, merge!

# ------------------------------------------------------------------------
# external dependencies part of the Franklin universe

import LiveServer
import FranklinParser
import FranklinParser: SS, Token, Block, Group,
                       subs, content, dedent, parent_string,
                       from, to, prev_index, next_index, next_chars
const FP = FranklinParser

# ------------------------------------------------------------------------
# external dependencies not part of the Franklin universe

import URIs
import IOCapture

# copied from CommonMark.jl, used in dealing with autolink
@inline issafe(c::Char) = c in "?:/,-+@._()#=*&%" ||
                          (isascii(c) && (isletter(c) || isnumeric(c)))
normalize_uri(s) = URIs.escapeuri(s, issafe)

# ------------------------------------------------------------------------
# Main functions
export serve, build, html, latex
export cur_gc

# XXX attach?
# export attach
# export auto_cell_name


# ------------------------------------------------------------------------

const FRANKLIN_ENV = Dict{Symbol, Any}(
    :module_name       => "Xranklin",     # TODO: remove here, in newmodule, in delay
    :strict_parsing    => false,          # if true, fail on any parsing issue
    :offset_lxdefs     => -typemax(Int),  # helps keep track of order in lxcoms/envs
    :cur_global_ctx    => nothing,        # current global context
    :cur_local_ctx     => nothing,        # current local context
    :skipped_files     => Set{String}(),
    :literate          => false,          # whether literate is loaded in utils
    :nocode            => false,          # whether to evaluate code cells
    :use_threads       => false,          # whether to use multithreading
    :lock              => ReentrantLock(),
)
env(s::Symbol)        = FRANKLIN_ENV[s]
setenv!(s::Symbol, v) = (FRANKLIN_ENV[s] = v; nothing)


const TIMER  = Dict{Float64,Pair{String, Float64}}()
const TIMERN = Ref(0)

nest()  = (TIMERN[] += 1)
dnest() = (TIMERN[] -= 1)

tic() = begin
    nest()
    t0 = time()
    TIMER[t0] = "" => 0.0
    return t0
end
toc(t0, s) = begin
    depth = dnest()
    δt = time() - t0
    s  = "."^depth * " (d:$depth) $s $(time_fmt(δt))" => δt
    @info s.first
    TIMER[t0] = s
    return
end

# ------------------------------------------------------------------------

include("misc_utils.jl")
include("html_utils.jl")

# ------------------------------------------------------------------------

# the ordering here is a bit awkard but we want contexts to point
# to 'Notebook' objects which are tied to code environment.

p = "context"
include("$p/types.jl")          # Vars, LxDef, PageHeadings, PageRefs, Anchor, Tag
include("$p/deps_map.jl")       # DepsMap, has_changed_deps
include("$p/notebook.jl")       # VarsNotebook, CodeNotebook
include("$p/context.jl")        # GlobalContext, LocalContext
include("$p/context_utils.jl")  # getvar, setvar, getdef, setdef, attach
include("$p/serialize.jl")
include("$p/anchors.jl")
include("$p/tags.jl")
include("$p/rss.jl")
include("$p/default_context.jl")

p = "context/code"
include("$p/modules.jl")
include("$p/notebook.jl")
include("$p/notebook_vars.jl")
include("$p/notebook_code.jl")

# ------------------------------------------------------------------------

include("convert/regex.jl")
include("convert/outputof.jl")

# ===> MARKDOWN

# >> LxFuns
p = "convert/markdown/lxfuns/"
include("$p/utils.jl")
include("$p/hyperrefs.jl")
include("$p/show.jl")
include("$p/literate.jl")
include("$p/misc.jl")

p = "convert/markdown/envfuns/"
include("$p/utils.jl")
include("$p/math.jl")

# >> LxObjects
p = "convert/markdown"
include("$p/latex_objects.jl")

# >> Core
include("$p/md_core.jl")

# >> Rules
p = "convert/markdown/rules/"
include("$p/utils.jl")
include("$p/text.jl")
include("$p/list.jl")
include("$p/table.jl")
include("$p/heading.jl")
include("$p/code.jl")
include("$p/math.jl")
include("$p/link.jl")

# ===> POSTPROCESSING

p = "convert/postprocess/hfuns"
include("$p/utils.jl")
include("$p/input.jl")
include("$p/hyperref.jl")
include("$p/evalstr.jl")
include("$p/henv.jl")
include("$p/henv_for.jl")
include("$p/henv_if.jl")
include("$p/tags_pagination.jl")
include("$p/dates.jl")

p = "convert/postprocess"
include("$p/dbb.jl")
include("$p/html2.jl")
include("$p/latex2.jl")

# ------------------------------------------------------------------------

p = "process"
include("$p/utils.jl")
include("$p/process.jl")
include("$p/config_utils.jl")
include("$p/html.jl")
include("$p/tex.jl")

include("$p/md/pass_1.jl")
include("$p/md/pass_i.jl")
include("$p/md/pass_2.jl")
include("$p/md/process.jl")


p = "build"
include("$p/paths.jl")
include("$p/watch.jl")
include("$p/full_pass.jl")
include("$p/build_loop.jl")
include("$p/serve.jl")

end
