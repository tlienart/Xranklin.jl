using Xranklin
using Test

include("utils.jl")

@testset "MD2HTML" begin
    p = "convert/md2html"
    include("$p/text+basic.jl")
end
