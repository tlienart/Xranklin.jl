@testset "text" begin
    let s = """
        A *B* _C_ **D**
        """
        @test html(s) //
                "<p>A <em>B</em> <em>C</em> <strong>D</strong></p>"
        @test latex(s) //
                raw"A \textit{B} \textit{C} \textbf{D}\par"
    end
end

@testset "indentation" begin
    # indentation is completely ignored
    let s = """
        ABC

            DEF

        GHI
        """
        h = html(s)
        l = latex(s)
        @test isapproxstr(h, "<p>ABC</p><p>DEF</p><p>GHI</p>")
        @test isapproxstr(l, "ABC\\par\nDEF\\par\nGHI\\par")
    end
end

@testset "div" begin
    let s = """
        A @@b C @@ @@d,e F@@ G
        """
        h = html(s)
        l = latex(s)
        @test isapproxstr(h, """
            <p>A</p>
            <div class="b">
              <p>C</p>
            </div>
            <div class="d e">
              <p>F</p>
            </div>
            <p>G</p>
            """)
        isbalanced(h)
        @test isapproxstr(l, raw"""
            A\par
            C\par
            F\par
            G\par
            """)
    end
end

@testset "div+indent" begin
    let s = raw"""
        ABC

            @@DEF

                \* \\ \{ \#

            @@

        GHI
        """
        h = html(s)
        l = latex(s)
        @test isapproxstr(h, """
            <p>ABC</p>
            <div class="DEF">
              <p>*<br>{ #</p>
            </div>
            <p>GHI</p>
            """)
        @test isapproxstr(l, raw"""
            ABC\par
            * \\ \{ \#\par
            GHI\par
            """)
    end
end

@testset "nesting divs" begin
    let s = """
        A
        @@B
          C D @@E F@@ G
        @@
        """
        h = html(s)
        l = latex(s)
        @test isapproxstr(h, """
            <p>A</p>
            <div class="B">
              <p>C D</p>
              <div class="E">
                <p>F</p>
              </div>
              <p>G</p>
            </div>
            """)
        isbalanced(h)
        @test isapproxstr(l, raw"""
            A\par
            C D\par
            F\par
            G\par
            """)
    end
end

@testset "br and hr" begin
    let s = raw"""
        A \\ B --- C
        """
        h = html(s)
        l = latex(s)
        @test isapproxstr(h, """
            <p>A<br>B</p>
            <hr>
            <p>C</p>
            """)
        @test isapproxstr(l, raw"""
            A \\ B\par
            \par\noindent\rule{\textwidth}{0.1pt}\par C\par
            """)
    end
end
