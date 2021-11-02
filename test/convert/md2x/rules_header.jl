include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "headers" begin
    let s = """
        # A
        ## B
        ### C
        #### D
        ##### E
        ###### F
        """
        h = html(s)
        l = latex(s)
        @test isapproxstr(h, """
            <h1 id="a"><a href="#a">A</a></h1>
            <h2 id="b"><a href="#b">B</a></h2>
            <h3 id="c"><a href="#c">C</a></h3>
            <h4 id="d"><a href="#d">D</a></h4>
            <h5 id="e"><a href="#e">E</a></h5>
            <h6 id="f"><a href="#f">F</a></h6>
            """)
        @test isapproxstr(l, raw"""
            \section{\label{a} A}
            \subsection{\label{b} B}
            \subsubsection{\label{c} C}
            D E F
            """)
    end
end
