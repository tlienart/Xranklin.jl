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
