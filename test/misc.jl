include("utils.jl")

@testset "string_to_anchor" begin
    s = "abc"
    @test X.string_to_anchor(s) // s

    s = " ^foo^"
    @test X.string_to_anchor(s) == "foo"
    @test X.string_to_anchor(s, keep_first_caret=true) == "^foo"
end
