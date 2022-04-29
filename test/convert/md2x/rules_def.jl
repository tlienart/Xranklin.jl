include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "mddef" begin
    gc = X.DefaultGlobalContext()
    lc = X.DefaultLocalContext(gc; rpath="loc")
    s = """
        @def x = 5
        """
    o = html(s, lc)
    @test isempty(o)
    @test X.getvar(lc, :x) == 5
    @test X.getvar(gc, :x) === nothing

    o = html(s, gc)
    @test X.getvar(gc, :x) == 5
end

@testset "mddef-block" begin
    lc = X.DefaultLocalContext(; rpath="loc")
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
    @test X.getvar(lc, :a) == 5
    @test X.getvar(lc, :b, "bye") == "hello"
    @test X.getvar(lc, :c) == [1 2; 3 4]
    @test year(X.getvar(lc, :d)) == 1
end
