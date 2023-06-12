include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "i194" begin
    s = raw"""
        +++
        t = "foo"
        +++
        abc {{fill t}} def {{t}} ghi
        """ |> html 
    @test isapproxstr(s, "<p>abc foo def foo ghi</p>")
end
