include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "CODE_LANG_PAT" begin
    s = "python!abc"
    l, e, n = match(X.CODE_LANG_PAT, s)
    @test l == "python"
    @test e == "!"
    @test n == "abc"

    l, e, n = match(X.CODE_LANG_PAT, "!abc")
    @test isnothing(l)
    @test e == "!"
    @test n == "abc"

    l, e, n = match(X.CODE_LANG_PAT, "::abc")
    @test e == "::"

    l, e, n = match(X.CODE_LANG_PAT, "lang>foo")
    @test l == "lang" # would be ignored
    @test e == ">"
    @test n == "foo"
end
