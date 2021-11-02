include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "mddef" begin
    gc = X.DefaultGlobalContext()
    lc = X.DefaultLocalContext(gc)
    s = """
        @def x = 5
        """
    o = html(s, lc)
    @test isempty(o)
    @test locvar(:x) == getvar(lc, :x) == 5
    @test globvar(:x) === nothing

    o = html(s, gc)
    @test globvar(:x) == getvar(gc, :x) == 5
end

@testset "mddef-block" begin
    lc = X.DefaultLocalContext()
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
    @test getvar(lc, :a) == 5
    @test getvar(lc, :b, "bye") == "hello"
    @test getvar(lc, :c) == [1 2; 3 4]
    @test year(getvar(lc, :d)) == 1
end
