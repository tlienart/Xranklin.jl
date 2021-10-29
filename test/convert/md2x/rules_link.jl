include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "basics" begin
    s = "[abc]"
    h = html(s; nop=true)
    @test isapproxstr(h, """
        <a href="abc">abc</a>
        """)
    l = latex(s; nop=true)
    @test isapproxstr(l, """
        \\href{abc}{abc}
        """)
    s = "[abc](def)"
    h = html(s; nop=true)
    @test isapproxstr(h, """
        <a href="def">abc</a>
        """)
    l = latex(s; nop=true)
    @test isapproxstr(l, """
        \\href{def}{abc}
        """)
end
