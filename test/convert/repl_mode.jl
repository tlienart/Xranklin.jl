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
        <pre><code class="julia-repl">julia> x = 5
        5
        
        julia> y = 7
        7
        
        julia> z = x+y
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
        # in case lines changes
        replace(s, r"\.\/math\.jl\:\d+" => "./math.jl:xx"),
        """
        <pre><code class="julia-repl">julia> sqrt(-1)
        ERROR: DomainError with -1.0:
        sqrt will only return a complex result if called with a complex argument. Try sqrt(Complex(x)).
        Stacktrace:
        [1] throw_complex_domainerror(f::Symbol, x::Float64)
            @ Base.Math ./math.jl:xx
        [2] sqrt
            @ ./math.jl:xx [inlined]
        [3] sqrt(x::Int64)
            @ Base.Math ./math.jl:xx
        
        julia> 2+2
        4
        </code></pre>
        """)
end
