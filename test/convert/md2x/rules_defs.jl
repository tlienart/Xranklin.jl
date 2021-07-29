include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "mddef" begin
    gc = X.GlobalContext()
    lc = X.LocalContext(gc)
    X.set_current_local_context(lc)
    s = """
        @def x = 5
        """
    o = html(s, lc)
    @test isempty(o)
    @test locvar(:x) == value(lc, :x) == 5
    @test globvar(:x) === nothing

    o = html(s, gc)
    @test globvar(:x) == value(gc, :x) == 5
end

@testset "mddef-block" begin
    lc = X.LocalContext()
    s = """
        +++
        using Dates
        a = 5
        b = "hello"
        c = [1 2
        3 4]
        d = Date(1)
        +++
        """
    o = html(s, lc)
    @test isempty(strip(o))
    @test value(lc, :a) == 5
    @test value(lc, :b, "bye") == "hello"
    @test value(lc, :c) == [1 2; 3 4]
    @test year(value(lc, :d)) == 1
end
