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
        <img src="def" alt="abc">
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
        <a href="D">
          A <em>B</em> <code>C[]</code>
        </a>
        """)
    @test isapproxstr(l, raw"""
        \href{D}{
          A \textit{B} \texttt{C[]}
        }
        """)
end

@testset "img ref" begin
    s = """
        ![A]
        [A]: B
        """
    h = html(s, nop=true)
    l = latex(s, nop=true)
    @test isapproxstr(h, """
        <img src="B" alt="A">
        """)

    # XXX should be post-processed in latex2 in some way
    @test isapproxstr(l, """
        {{img_a a "A"}}
        """)
end

@testset "link ref with conv" begin
    s = """
        [A **B** `[C]`]
        [A **B** `[C]`]: foo
        """
    h = html(s, nop=true)
    @test isapproxstr(h, """
        <a href="foo">A <strong>B</strong> <code>[C]</code></a>
        """)
end

@testset "ref with no ref" begin
    s = "[A] ![B]"
    h = html(s, nop=true)
    @test isapproxstr(h, s)
end

@testset "autolink" begin
    l = "https://example.com"
    s = "<$l>"
    @test html(s, nop=true) // "<a href=\"$l\">$l</a>"
    @test latex(s, nop=true) // raw"\href{https://example.com}{https://example.com}"
end
