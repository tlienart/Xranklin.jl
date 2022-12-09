include(joinpath(@__DIR__, "..", "..", "utils.jl"))

# dingus https://spec.commonmark.org/dingus/

@testset "base" begin
    let s = """
        * A
        * B
        """
        h = html(s)
        @test isapproxstr(h, """
            <ul>
              <li>A</li>
              <li>B</li>
            </ul>
            """)
        l = latex(s)
        @test isapproxstr(l, raw"""
            \begin{itemize}
            \item A
            \item B
            \end{itemize}
            """)
    end

    let s = """
        1. A
        1. B
        """
        h = html(s)
        l = latex(s)
        @test isapproxstr(h, """
            <ol>
            <li>A</li>
            <li>B</li>
            </ol>
            """)
        @test isapproxstr(l, raw"""
            \begin{enumerate}
            \item A
            \item B
            \end{enumerate}
            """)
    end
end

@testset "item conversion" begin
    let s = """
        * A **B** `C`
        * D _E_
        """
        h = html(s)
        @test isapproxstr(h, """
            <ul>
            <li>A <strong>B</strong> <code>C</code></li>
            <li>D <em>E</em></li>
            </ul>
            """)
        l = latex(s)
        @test isapproxstr(l, raw"""
            \begin{itemize}
            \item A \textbf{B} \texttt{C}
            \item D \textit{E}
            \end{itemize}
            """)
    end
end

@testset "indentation" begin
    # excess indentation doesn't matter
    s = """
        * A
            * B
          * B2
        * C
          * D
            * D2
        """
    h = html(s)
    # NOTE: from dingus
    @test isapproxstr(h, """
        <ul>

         <li>A<ul>
          <li>B</li>
          <li>B2</li>
         </ul></li>

         <li>C<ul>

          <li>D<ul>
           <li>D2</li>
          </ul></li>

         </ul></li>

        </ul>
        """)
end

@testset "mixing" begin
    # NOTE: in `A1` the `*` are sufficiently indented, we just require two spaces or more
    s = """
        * A
          1. As1
          1. As2
        1. A1
          * Bs
          * Cs
         1. B1
        """
    h = html(s)
    @test isapproxstr(h, """
        <ul>

         <li>A<ol>
          <li>As1</li>
          <li>As2</li>
         </ol></li>

        </ul>
        <ol>

         <li>A1<ul>
          <li>Bs</li>
          <li>Cs</li>
         </ul></li>

         <li>B1</li>
        </ol>
        """)
end

@testset "list in indent" begin
    let s = """
          A
            * B
            * C

          D
          """
        h = html(s)
        @test isapproxstr(h, """
            <p>A</p>
            <ul>
             <li>B</li>
             <li>C</li>
            </ul>
            <p>D</p>
            """)
    end

    let s = """
            @@foo
                * A
                * B
            @@
            """
        h = html(s)
        @test isapproxstr(h, """
            <div class="foo">
             <ul>
              <li>A</li>
              <li>B</li>
             </ul>
            </div>
            """)
    end
end

@testset "cm1" begin
    case = """
      * a
          * b
        * c
          * d
      """
    expected = """
      <ul>
        <li>a
          <ul>
            <li>b</li>
            <li>c
              <ul>
                <li>d</li>
              </ul>
            </li>
          </ul>
        </li>
      </ul>
      """
    @test isapproxstr(html(case), expected)
end

@testset "cm2" begin
    h = """
      * a
      1. b
      * c
      """ |> html
    expected = """
      <ul>
        <li>a</li>
      </ul>
      <ol>
        <li>b</li>
      </ol>
      <ul>
        <li>c</li>
      </ul>
      """
    @test isapproxstr(h, expected)
end

@testset "cm3" begin
    h = """
      * a
        1. b
        * c
      """ |> html
    expected = """
      <ul>
        <li>a
          <ol>
            <li>b</li>
          </ol>
          <ul>
            <li>c</li>
          </ul>
        </li>
      </ul>
    """
    @test isapproxstr(h, expected)
end

@testset "i#8" begin
    h = raw"""
        \newcommand{\foo}{abc}

       * a
       * b

       * a
       * \foo
       """ |> html
    @test isapproxstr(h, """
        <ul>
            <li>a</li>
            <li>b</li>
        </ul>
        <ul>
            <li>a</li>
            <li>abc</li>
        </ul>
        """)
end

@testset "ol-start" begin
    s = """
        2. abc
        1. def
        0. ghi
        """
    h = s |> html
    l = s |> latex
    @test isapproxstr(h, """
        <ol start="2">
          <li>
            abc
          </li>
          <li>
            def
          </li>
          <li>
            ghi
          </li>
        </ol>""")
end

@testset "i#172" begin
    # this was an issue with FranklinParser
    s = """
       * abc
       * def
       ghi [klm](mno.com).

       """
    h = s |> html
    @test isapproxstr(h, """
        <ul>
          <li>abc</li>
          <li>def
          ghi <a href="mno.com">klm</a>.</li>
        </ul>
        """)
end
