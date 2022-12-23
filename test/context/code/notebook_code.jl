include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "nb-code" begin
    gc = X.DefaultGlobalContext()
    X.setvar!(gc, :skiplatex, false)
    lc = X.DefaultLocalContext(gc; rpath="foo")
    nb = lc.nb_code
    @test isa(nb, X.CodeNotebook)
    c = """
        a = 5
        a^2
        """
    X.eval_code_cell!(lc, X.subs(c), "abc")
    @test X.counter(nb) == 2
    @test length(nb) == 1
    @test nb.code_pairs[1].repr.html // """
        <pre><code class="code-result language-plaintext">25</code></pre>"""
    @test nb.code_pairs[1].repr.latex == "25"

    # - simulating modification of the samecell
    X.reset_counter!(nb)
    X.eval_code_cell!(lc, X.subs(c * ";"), "abc")
    @test length(nb) == 1
    @test nb.code_pairs[1].repr.html === ""
    @test nb.code_names[1] == "abc"

    X.eval_code_cell!(lc, X.subs("a^3"), "def")
    @test X.counter(nb) == 3
    @test length(nb) == 2
    @test nb.code_pairs[2].repr.html //"""
        <pre><code class="code-result language-plaintext">125</code></pre>"""
    @test nb.code_names[2] == "def"

    X.eval_code_cell!(lc, X.subs("@show a"), "sss")
    @test X.counter(nb) == 4
    @test length(nb) == 3
    @test nb.code_pairs[3].repr.html // """
        <pre><code class=\"code-stdout language-plaintext\">a = 5\n</code></pre>"""
    @test nb.code_names[3] == "sss"
end
