include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "basics" begin
    s = "[abc](def)"
    h = html(s; nop=true)
    @test isapproxstr(h, """
        <a href="def">abc</a>
        """)
    l = latex(s; nop=true)
    @test isapproxstr(l, """
        \\href{def}{abc}
        """)

    s = "![abc](def)"
    h = html(s; nop=true)
    @test isapproxstr(h, """
        <img src="def" alt="abc" >
        """)
    l = latex(s; nop=true)
    @test isapproxstr(l, raw"""
        \begin{figure}[!h]
            \includegraphics[width=0.5\textwidth]{def}
            \caption{abc}
        \end{figure}
        """)
end

@testset "ref" begin
    s = "[A]: https://example.com"
    h = html(s, nop=true)
    @test locvar(:_refrefs)["a"] == "https://example.com"
    s = """
        [A]
        [A]: https://foo.bar
        """
    h = html(s, nop=true)
    @test isapproxstr(h, """
            <a href="https://foo.bar">A</a>
            """)
end

@testset "link with conv" begin
    s = "[A *B* `C[]`](D)"
    h = html(s, nop=true)
    l = latex(s, nop=true)
    @test isapproxstr(h, """
        <a href="D">A <em>B</em> <code>C[]</code></a>
        """)
    @test isapproxstr(l, raw"""
        \href{D}{A \textit{B} \texttt{C[]}}
        """)
end

# s = "[abc]"
# h = html(s; nop=true)
# @test isapproxstr(h, """
#     <a href="abc">abc</a>
#     """)
# l = latex(s; nop=true)
# @test isapproxstr(l, """
#     \\href{abc}{abc}
#     """)
