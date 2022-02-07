include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "basic outputs" begin
    # basic type
    s = raw"""
        ```julia:ex
        true
        ```
        \show{ex}
        """
    h = html(s, nop=true)
    @test isapproxstr(h, """
        <pre><code class="julia">true</code></pre>
        <div class="code-output">
            <pre><code class="code-result language-plaintext">true</code></pre>
        </div>
        """)
    s = raw"""
        ```julia:ex
        "abc"
        ```
        \show{ex}
        """
    h = html(s, nop=true)
    @test isapproxstr(h, """
        <pre><code class="julia">&quot;abc&quot;</code></pre>
        <div class="code-output">
            <pre><code class="code-result language-plaintext">"abc"</code></pre>
        </div>
        """)

    # basic stdout
    s = raw"""
        ```julia:ex
        println("hello")
        ```
        \show{ex}
        """
    h = html(s, nop=true)
    @test occursin("<pre><code class=\"code-stdout language-plaintext\">hello\n</code></pre>", h)

    # basic hidden output
    s = raw"""
        ```julia:ex
        true;
        ```
        \show{ex}
        """
    h = html(s, nop=true)
    @test isapproxstr(h, """
        <pre><code class="julia">true;</code></pre>
        """)

    # basic stderr
    s = raw"""
        ```julia:ex
        sqrt(-1)
        ```
        \show{ex}
        """
    h = html(s, nop=true)
    @test occursin("""<pre><code class="julia">sqrt(-1)</code></pre>""", h)
    @test occursin("""<pre><code class="code-stderr language-plaintext">LoadError: DomainError with -1.0:""", h)
    @test occursin("""sqrt will only return a complex result if called with a complex argument. Try sqrt(Complex(x)).""", h)
    @test occursin("""Stacktrace:""", h)
    @test occursin("""throw_complex_domainerror""", h)
end

@testset "figure" begin
    d, gc = testdir()
    s = raw"""
        ```julia:ex
        using Images
        rand(Gray, 2, 2)
        ```
        \show{ex}
        """
    h = html(s, X.DefaultLocalContext(gc), nop=true)
    @test isapproxstr(h, """
        <pre><code class="julia">using Images
        rand(Gray, 2, 2)</code></pre>
        <div class="code-output">
          <img class="code-figure" src="/assets/figs-html/__autofig_911582796084046168.svg">
        </div>
        """)
    @test isfile(d / "__site" / "assets" / "figs-html" / "__autofig_911582796084046168.svg")
end

@testset "custom show" begin
    gc = X.DefaultGlobalContext()
    utils = raw"""
        struct Foo
            x::Int
        end
        foo() = 5
        html_show(i::Int) = "<span>Int: $i</span>"
        html_show(f::Foo) = "<span>Foo: $(f.x)</span>"
        """
    X.process_utils(utils, gc)

    s = raw"""
        ```:ex
        1
        ```
        \show{ex}
        """
    h = html(s, X.DefaultLocalContext(gc), nop=true)
    @test isapproxstr(h, """
        <pre><code class="julia">1</code></pre>
        <div class="code-output">
            <span>Int: 1</span>
        </div>
        """)

    s = raw"""
        ```:ex
        Utils.Foo(1)
        ```
        \show{ex}
        """
    h = html(s, X.DefaultLocalContext(gc), nop=true)
    @test isapproxstr(h, """
        <pre><code class="julia">Utils.Foo(1)</code></pre>
        <div class="code-output">
            <span>Foo: 1</span>
        </div>
        """)

    utils = raw"""
        import Base.show
        struct Foo
            y::Int
        end
        html_show(f::Foo) = "<span>Bar: $(f.y)</span>"
        """
    gc = X.DefaultGlobalContext()
    X.process_utils(utils, gc)
    lc = X.DefaultLocalContext(gc)
    h = html(s, lc, nop=true)
    @test isapproxstr(h, """
        <pre><code class="julia">Utils.Foo(1)</code></pre>
        <div class="code-output">
            <span>Bar: 1</span>
        </div>
        """)

    s = raw"""
        ```:ex
        5
        ```
        \show{ex}
        """
    h = html(s, X.DefaultLocalContext(gc), nop=true)
    @test isapproxstr(h, """
        <pre><code class="julia">5</code></pre>
        <div class="code-output">
            <pre><code class="code-result language-plaintext">5</code></pre>
        </div>
        """)
end
