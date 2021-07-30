include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "mddef" begin
    gc = X.DefaultGlobalContext()
    lc = X.DefaultLocalContext(gc)
    X.set_current_local_context(lc)
    @test isempty(locvar(:_md_def_hashes))
    s = """
        @def x = 5
        """
    o = html(s, lc)
    @test isempty(o)
    @test locvar(:x) == getvar(lc, :x) == 5
    @test globvar(:x) === nothing
    @test !isempty(locvar(:_md_def_hashes))

    o = html(s, gc)
    @test globvar(:x) == getvar(gc, :x) == 5
    @test !isempty(globvar(:_md_def_hashes))
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

@testset "skip re-val" begin
    lc = X.DefaultLocalContext()
    s = """
        +++
        a = 7
        b = 8
        +++
        """
    o = html(s * "\nabc", lc)
    @test length(lc.vars[:_md_def_hashes]) == 1
    # no reeval
    o = html(s * "\ndef", lc)
    @test length(lc.vars[:_md_def_hashes]) == 1
end
