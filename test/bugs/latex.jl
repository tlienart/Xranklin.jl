include(joinpath(@__DIR__, "..", "utils.jl"))

# -- Feb 10 | Timothy Lin's website

@testset "align mess" begin
    s = raw"""
        \newcommand{\reason}[1]{\quad\text{#1}}

        \begin{align}
            \mathbb{E}\big[ k \big] &= \dfrac{1-p}{p}\Big\vert_{p = \frac{1}{n-i}} \\
            &= \dfrac{1-\frac{1}{n-i}}{\frac{1}{n-i}} \\
            &= n - i - 1,
        \end{align}

        \begin{align}
            \mathbb{E}\big[ T(n) \big] &= \sum_{i=0}^{n-1} \mathbb{E}\big[ \text{Inner}(i) \big] \\
            &= \sum_{i=0}^{n-1} 2(n-i)\mathbb{E}\big[ k \big] + 2(n-i) \\
            &= \sum_{i=0}^{n-1} 2(n-i)(n-i-1) + 2(n-i) \\
            &= 2 \sum_{i=0}^{n-1} (n-i)^2 \\
            &= 2 \sum_{i=1}^n i^2 \reason{(change of variables)} \\
            &= \dfrac{n(n+1)(2n+1)}{3} \reason{(sum of squares)} \\
            &\in O(n^3)
        \end{align}
        """
    h = html(s)
end

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
