include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "repl-repl" begin
    s = """
        ```>
        x = 5
        y = 7
        z = x+y
        ```
        """ |> html
    @test isapproxstr(s, """
        <pre><code class="julia-repl">julia&gt; x = 5
        5
        
        julia&gt; y = 7
        7
        
        julia&gt; z = x+y
        12
        </code></pre>
        """)
    
    s = """
        ````>
        sqrt(-1)
        2+2
        ````
        """ |> html
    @test isapproxstr(
        # in case lines changes in Julia
        replace(s, r"\.\/math\.jl\:\d+" => "./math.jl:xx"),
        """
        <pre><code class="julia-repl">julia&gt; sqrt(-1)
        ERROR: DomainError with -1.0:
        sqrt will only return a complex result if called with a complex argument. Try sqrt(Complex(x)).
        Stacktrace:
          [1] throw_complex_domainerror(f::Symbol, x::Float64)
            @ Base.Math ./math.jl:xx
          [2] sqrt
            @ ./math.jl:xx [inlined]
          [3] sqrt(x::Int64)
            @ Base.Math ./math.jl:xx
        
        julia&gt; 2+2
        4
        </code></pre>
        """)
end

@testset "repl-shell" begin
    s = """
        ```;
        echo abc
        echo def
        ```
        """ |> html
    @test isapproxstr(s, """
        <pre><code class="julia-repl">shell&gt; echo abc
        abc
        
        shell&gt; echo def
        def
        </code></pre>
        """)
end

@testset "repl-pkg" begin
    cur_proj = Pkg.project().path
    s = """
        ```]
        activate --temp
        add Colors
        ```
        then
        ```!
        using Colors
        colorant"red"
        ```
        """ |> html
    Pkg.activate(cur_proj)

    for q in (
            "($(splitpath(cur_proj)[end-1])) pkg&gt; activate --temp",
            "pkg&gt; add Colors\nResolving package versions...",
            """<pre><code class=\"julia\">using Colors\ncolorant&quot;red&quot;</code></pre>""",
            """<div class=\"code-output\"><img class=\"code-figure\""""
        )
        @test occursin(q, s)
    end
end
