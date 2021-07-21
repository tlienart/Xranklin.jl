using Xranklin, Test, Dates; X = Xranklin

@testset "mddef" begin
    X.setenv(:cur_local_ctx, nothing)
    gc = X.GlobalContext()
    lc = X.LocalContext(gc)
    s = """
        @def x = 5
        """
    o = html(s, lc)
    @test isempty(o)
    @test value(lc, :x) == 5

    o = html(s, gc)
    @test value(gc, :x) == 5
    @test globvar(:x) === nothing

    X.set_current_local_context(lc)
    @test globvar(:x) == 5
    @test locvar(:x) == 5
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
