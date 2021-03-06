using Xranklin
using Test
const X = Xranklin

X.FRANKLIN_ENV[:STRICT_PARSING] = false
X.FRANKLIN_ENV[:SHOW_WARNINGS] = false

include("utils.jl")

@testset "LaTeX" begin
    include("convert/md_latex_newobj.jl")
    include("convert/md_latex_obj.jl")
end

@testset "MD2x" begin
    p = "convert/md2x"
    include("$p/resolve_inline.jl")
    include("$p/rules_text.jl")
    include("$p/rules_maths.jl")
end
