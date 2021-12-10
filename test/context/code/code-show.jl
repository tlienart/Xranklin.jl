include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "outputs" begin
    s = raw"""
        ```julia:ex
        true
        ```
        \show{ex}
        """
    h = html(s, nop=true)
    @test isapproxstr(h, """
        <pre><code class="julia">true</code></pre>
        <pre><code class="code-output">true</code></pre>
        """)
end
