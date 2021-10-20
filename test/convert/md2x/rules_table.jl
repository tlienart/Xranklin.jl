include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "simple" begin
    let s = """
        | a | b |
        | - | - |
        | 1 | 0 |
        """
        h = html(s)
        l = latex(s)
        @test isapproxstr(h, """
            <table>
             <thead>
              <th > a </th>
              <th > b </th>
             </thead>
             <tbody>
              <tr>
               <td > 1 </td>
               <td > 0 </td>
              </tr>
             </tbody>
            </table>
            """)
        @test isapproxstr(l, raw"""
            \begin{tabular}{cc}
            \toprule
            a  &  b  \\
            \midrule
            1  &  0  \\
            \bottomrule
            \end{tabular}
            """)
    end

    let s = """
        | a | b | c |
        | :- | -: | :-: |
        | 1 | 0 | 2 |
        | 3 | 4 | 5 |
        """
        h = html(s)
        @test isapproxstr(h, """
            <table>
             <thead>
              <th style="text-align:left;"> a </th>
              <th style="text-align:right;"> b </th>
              <th style="text-align:center;"> c </th>
             </thead>
             <tbody>
              <tr>
               <td style="text-align:left;"> 1 </td>
               <td style="text-align:right;"> 0 </td>
               <td style="text-align:center;"> 2 </td>
              </tr>
              <tr>
               <td style="text-align:left;"> 3 </td>
               <td style="text-align:right;"> 4 </td>
               <td style="text-align:center;"> 5 </td>
              </tr>
             </tbody>
            </table>
            """)
        l = latex(s)
        @test isapproxstr(l, raw"""
            \begin{tabular}{lrc}
            \toprule
            a  &  b  &  c  \\
            \midrule
            1  &  0  &  2  \\
            3  &  4  &  5  \\
            \bottomrule
            \end{tabular}
            """)
    end
end


@testset "inconsistent cols" begin
    let s = """
        | a | b |
        | - | - | :-: |
        | 1 | 0 | 2 |
        | 3 | 4 | 5 |
        """
        h = html(s)
        @test isapproxstr(h, """
            <table>
             <thead>
              <th > a </th>
              <th > b </th>
              <th style="text-align:center;"></th>
             </thead>
             <tbody>
              <tr>
               <td > 1 </td>
               <td > 0 </td>
               <td style="text-align:center;"> 2 </td>
              </tr>
              <tr>
               <td > 3 </td>
               <td > 4 </td>
               <td style="text-align:center;"> 5 </td>
              </tr>
             </tbody>
            </table>
            """)
        l = latex(s)
        @test isapproxstr(l, raw"""
            \begin{tabular}{ccc}
            \toprule
             a  &  b  &  \\
            \midrule
             1  &  0  &  2  \\
             3  &  4  &  5  \\
            \bottomrule
            \end{tabular}
            """)
    end
    let s = """
        |a|b|c|
        |:-|:-|
        |0|1|2|3|
        """
        h = html(s)
        @test isapproxstr(h, """
            <table>
             <thead>
              <th style="text-align:left;">a</th>
              <th style="text-align:left;">b</th>
              <th >c</th>
              <th ></th>
             </thead>
             <tbody>
              <tr>
               <td style="text-align:left;">0</td>
               <td style="text-align:left;">1</td>
               <td >2</td>
               <td >3</td>
              </tr>
             </tbody>
            </table>
            """)
        l = latex(s)
        @test isapproxstr(l, raw"""
            \begin{tabular}{llcc}
            \toprule
            a & b & c &  \\
            \midrule
            0 & 1 & 2 & 3 \\
            \bottomrule
            \end{tabular}
            """)
    end
end


@testset "with conversion" begin
    let s = raw"""
        | a | *b* |
        | - | --- |
        | 1 | 0 `|`|
        | 3 | $x$ |
        """
        h = html(s)
        @test isapproxstr(h, raw"""
            <table>
             <thead>
              <th > a </th>
              <th > <em>b</em> </th>
             </thead>
             <tbody>
              <tr>
               <td > 1 </td>
               <td > 0 <code>|</code></td>
              </tr>
              <tr>
               <td > 3 </td>
               <td > \(x\) </td>
              </tr>
             </tbody>
            </table>
            """)
        l = latex(s)
        @test isapproxstr(l, raw"""
            \begin{tabular}{cc}
            \toprule
             a  &  \textit{b}  \\
            \midrule
             1  &  0 \texttt{|} \\
             3  &  $x$  \\
            \bottomrule
            \end{tabular}
            """)
    end
end
