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
end
