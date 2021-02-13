@testset "newcommand" begin
    s = raw"""
        abc \newcommand{\foo}{bar} def
        """
    c = X.EmptyContext()
    h = html(s, c)
    @test isapproxstr(h, "<p>abc</p> <p>def</p>")
    @test length(c.lxdefs) == 1
    d = c.lxdefs[1]
    @test d.name == "foo"
    @test d.nargs == 0
    @test d.def == "bar"
    @test d.from > 0
    @test d.to > d.from
end
