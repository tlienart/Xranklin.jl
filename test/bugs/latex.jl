include(joinpath(@__DIR__, "..", "utils.jl"))

# -- Nov 29

@testset "newcom+math" begin
    c = X.DefaultLocalContext()
    s = raw"""
        \newcommand{\E}[1]{
            \mathbb E\left[#1\right]
        }
        $$\E{\sum_{i=1}x_i} = 0$$
        """
    h = html(s, c, nop=true)
    # this works fine
    @test isapproxstr(h, raw"""
        \[ \mathbb E\left[ \sum_{i=1}x_i\right] = 0 \]
        """)

        s = raw"""
            \newcommand{\ca}[1]{
            ````markdown
            #1
            ````
            #1
            }

            \ca{
                \newcommand{\E}[1]{\mathbb E\left\{#1\right\}}
                $$ x \in \E{X} $$
            }
            """
    # used to stackoverflow
    h = html(s,  nop=true)
    @test isapproxstr(h, raw"""
    <pre><code class="markdown">
      \newcommand&lbrace;\E&rbrace;[1]&lbrace;\mathbb E\left\&lbrace;#1\right\&rbrace;&rbrace;
      $$ x \in \E&lbrace;X&rbrace; $$
    </code></pre>
    \[  x \in \mathbb E\left\{ X\right\}  \]
    """)
end
