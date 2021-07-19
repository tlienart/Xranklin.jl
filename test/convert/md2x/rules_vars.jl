using Xranklin, Test; X = Xranklin

@testset "mddef" begin
    lc = X.LocalContext()
    s = """
        @def x = 5
        """
    o = html(s, lc)
    @test isempty(o)
    @test value(lc, :x) == 5
end
