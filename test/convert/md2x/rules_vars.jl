using Xranklin, Test; X = Xranklin

@testset "mddef" begin
    X.FRANKLIN_ENV[:CUR_LOCAL_CTX] = nothing
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
