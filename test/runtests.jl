using Xranklin
using Test
const X = Xranklin

include("utils.jl")

@testset "LaTeX" begin
    include("convert/md_latex_obj.jl")
end

@testset "MD2HTML" begin
    p = "convert/md2html"
    include("$p/resolve_inline.jl")
    include("$p/rules_text.jl")
end

@testset "MD2LATEX" begin
    p = "convert/md2latex"
    include("$p/resolve_inline.jl")
    include("$p/rules_text.jl")
end
