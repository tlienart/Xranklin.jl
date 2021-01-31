using Xranklin
using Test

include("utils.jl")

@testset "MD2HTML" begin
    p = "convert/md2html"
    include("$p/resolve_inline.jl")
    include("$p/rules_basic.jl")
end
