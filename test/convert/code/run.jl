include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "run_code" begin
    pm = X.page_module("foo", wipe=true)
    r = X.run_code(pm, SubString("""
        a = 5
        a^2
        """))
    @test r == 25
    tp = tempname()
    r = X.run_code(pm, SubString("""
        a = 5
        @show a^5
        """), tp)
    @test read(tp, String) // "a ^ 5 = 3125"
    @test r === nothing
    tp = tempname()
    r = X.run_code(pm, SubString("""
        a = 5
        a^2;
        """), tp)
    @test r === nothing
    @test read(tp, String) // ""
end
