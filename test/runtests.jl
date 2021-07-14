using Xranklin, LiveServer
using Test
const X = Xranklin

X.FRANKLIN_ENV[:STRICT_PARSING] = false
X.FRANKLIN_ENV[:SHOW_WARNINGS] = false

include("utils.jl")
include("integration.jl")

@testset "LaTeX" begin
    p = "convert/"
    include("$p/md_latex_newobj.jl")
    include("$p/md_latex_obj.jl")
end

@testset "MD2x" begin
    p = "convert/md2x"
    include("$p/resolve_inline.jl")
    # rules
    include("$p/rules_text.jl")
    include("$p/rules_headers.jl")
    include("$p/rules_maths.jl")
    # include("$p/rules_code.jl")
    # utils
    # include("$p/utils.jl")
end
