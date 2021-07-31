include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "run_code" begin
    pm = X.submodule(:foo, wipe=true)
    r = X.run_code(pm, SubString("""
        a = 5
        a^2
        """))
    @test r == 25
    tp = tempname()
    r = X.run_code(pm, SubString("""
        a = 5
        @show a^5
        """), out_path=tp)
    @test read(tp, String) // "a ^ 5 = 3125"
    @test r === nothing
    tp = tempname()
    r = X.run_code(pm, SubString("""
        a = 5
        a^2;
        """), out_path=tp)
    @test r === nothing
    @test read(tp, String) // ""
end
