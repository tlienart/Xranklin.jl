include(joinpath(@__DIR__, "..", "utils.jl"))

JULIA = "<span class=\"sgr32\"><span class=\"sgr1\">julia&gt;</span></span>"
SHELL = "<span class=\"sgr31\"><span class=\"sgr1\">shell&gt;</span></span>"
HELP  = "<span class=\"sgr33\"><span class=\"sgr1\">help?&gt;</span></span>"

@testset "repl-repl" begin
    s = """
        ```>
        x = 5
        y = 7
        z = x+y
        ```
        """ |> html
    @test isapproxstr(s, """
        <pre><code class="julia-repl">$JULIA x = 5
        5
        
        $JULIA y = 7
        7
        
        $JULIA z = x+y
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
        <pre><code class="julia-repl">$JULIA sqrt(-1)
        ERROR: DomainError with -1.0:
        sqrt will only return a complex result if called with a complex argument. Try sqrt(Complex(x)).
        Stacktrace:
          [1] throw_complex_domainerror(f::Symbol, x::Float64)
            @ Base.Math ./math.jl:xx
          [2] sqrt
            @ ./math.jl:xx [inlined]
          [3] sqrt(x::Int64)
            @ Base.Math ./math.jl:xx
        
        $JULIA 2+2
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
        <pre><code class="julia-repl">$SHELL echo abc
        abc
        
        $SHELL echo def
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
            "<span class=\"sgr34\"><span class=\"sgr1\">($(splitpath(cur_proj)[end-1])) pkg&gt;</span></span> activate --temp",
            "pkg&gt;</span></span> add Colors",
            "Resolving</span></span> package versions...",
            """<pre><code class=\"julia\">using Colors\ncolorant&quot;red&quot;</code></pre>""",
            """<div class=\"code-output\"><img class=\"code-figure\""""
        )
        @test occursin(q, s)
    end
end

@testset "repl-help" begin
    s = """
        ```?
        im
        ```
        """ |> html

    for q in (
        """<pre><code class="julia-repl">$HELP im""",
        """<div class=\"repl-help\">\n<pre><code>im</code></pre>""",
        )
        @test occursin(q, s)
    end
end
