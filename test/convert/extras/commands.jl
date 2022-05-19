include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "eqref counters + nonumber" begin
    h = html(raw"""
        $$ x = 1 \label{label 1}$$
        \nonumber{
        $$ x = 2 $$
        }
        $$ x = 3 \label{label 2}$$
        \nonumber{
        $$ x = 4 $$
        }
        $$ x = 5 \label{label 3}$$

        \eqref{label 1} \eqref{label 2} \eqref{label 3}
        """)

    for i in 1:3
        has(h, """(<a href="#label_$i" class="eqref">$i</a>)""")
    end
    for i in (2, 4)
        has(h, raw"""<div class="nonumber">\[  x = """ * "$i" * raw"""  \]""")
    end
end
