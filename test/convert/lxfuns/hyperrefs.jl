include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "bibrefs/biblabel/cite" begin
    gc, lc = toy_context()

    # biblabel
    s = raw"""
        * \biblabel{abc04}{ABC (2004)} Something ABC (2004)
        """
    h = html(s, lc)
    @test isapproxstr(h, """
        <ul>
         <li>
          <a id="abc04" class="anchor anchor-bib"></a>
           Something ABC (2004)
         </li>
        </ul>
        """)
    
    # query bibrefs via cite
    s = raw"""
        See for instance \cite{abc04}.
        """
    h = html(s, lc)
    @test isapproxstr(h, """
        <p>See for instance
          <a href="#abc04" class="bibref">ABC (2004)</a>.
        </p>
        """)
    
    # the id and ordering is not strict
    s = raw"""
        \biblabel{non strict 04}{Something not strict 2004}

        cf. \cite{non strict 04}
        """
    h = html(s, lc)
    @test isapproxstr(h, """
        <a id="non_strict_04" class="anchor anchor-bib"></a>
        <p>
         cf.
          <a href="#non_strict_04" class="bibref">
           Something not strict 2004
          </a>
        </p>
        """)
end


@testset "label/eqref" begin
    gc, lc = toy_context()
    s = raw"""
        Some eq:
        $$ x = 7 \label{foo bar} $$
        Then ref to \eqref{foo bar}.
        """
    h = html(s, lc)
    @test isapproxstr(h, raw"""
        <p>Some eq:</p>
         <a id="foo_bar" class="anchor anchor-math"></a>
          \[  x = 7   \]
        <p>
         Then ref to 
          (<a href="#foo_bar" class="eqref">1</a>).
        </p>
    """)
end


@testset "toc" begin
    gc, lc = toy_context()
    s = raw"""
        \toc
        # ABC 1
        ## DEF 11
        ## GHI 12k
        # JKL 2
        ## MNO 21
        ### PQR 211
        """
    h = html(s, lc)

    @test isapproxstr(h, """
        <div class="toc">
          <ol>
            <li>
              <a href="#abc_1">ABC 1</a>
              <ol>
                <li>
                  <a href="#def_11">DEF 11</a>
                </li>
                <li>
                  <a href="#ghi_12k">GHI 12k</a>
                </li>
              </ol>
            </li>
            <li>
              <a href="#jkl_2">JKL 2</a>
              <ol>
                <li>
                  <a href="#mno_21">MNO 21</a>
                  <ol>
                    <li>
                      <a href="#pqr_211">PQR 211</a>
                    </li>
                  </ol>
                </li>
              </ol>
            </li>
          </ol>
        </div>
        
        <h1 id="abc_1" ><a href="#abc_1"> ABC 1</a></h1>
        <h2 id="def_11" ><a href="#def_11"> DEF 11</a></h2>
        <h2 id="ghi_12k" ><a href="#ghi_12k"> GHI 12k</a></h2>
        <h1 id="jkl_2" ><a href="#jkl_2"> JKL 2</a></h1>
        <h2 id="mno_21" ><a href="#mno_21"> MNO 21</a></h2>
        <h3 id="pqr_211" ><a href="#pqr_211"> PQR 211</a></h3>
    """)

end
