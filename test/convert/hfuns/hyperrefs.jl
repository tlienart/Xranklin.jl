include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "footnotes/filtered footnotes" begin
    # unfiltered, everything in one shot:
    s = """
        [^1]: abc
        [^2]: def
        [^3]: ghi

        {{footnotes}}

        [^4]: klm
        [^5]: nop
        """ |> html
    @test isapproxstr(s, """
        <div class="fn-defs">
        <a id="fn-defs"></a>
        <div class="fn-title">Notes</div>
        <ol>
            <li>
                <a id="fn_1"></a>
                <a href="#fnref_1" class="fn-hook-btn">&ldca;</a>
                abc
            </li>
            <li>
                <a id="fn_2"></a>
                <a href="#fnref_2" class="fn-hook-btn">&ldca;</a>
                def
            </li>
            <li>
                <a id="fn_3"></a>
                <a href="#fnref_3" class="fn-hook-btn">&ldca;</a>
                ghi
            </li>
            <li>
                <a id="fn_4"></a>
                <a href="#fnref_4" class="fn-hook-btn">&ldca;</a>
                klm
            </li>
            <li>
                <a id="fn_5"></a>
                <a href="#fnref_5" class="fn-hook-btn">&ldca;</a>
                nop
            </li>
        </ol>
        </div>
        """
    )

    # filtering
    s = """
        ABC

        [^1]: abc
        [^2]: def
        [^3]: ghi

        {{footnotes 1 2 3}}

        DEF

        [^a fn 4]: klm
        [^a fn 5]: nop

        {{footnotes "a fn 4" "a fn 5"}}
        """ |> html
    isapproxstr(s, """
        <p>ABC</p>
        <div class="fn-defs">
        <a id="fn-defs"></a>
        <div class="fn-title">Notes</div>
        <ol>
            <li>
                <a id="fn_1"></a>
                <a href="#fnref_1" class="fn-hook-btn">&ldca;</a>
                abc
            </li>
            <li>
                <a id="fn_2"></a>
                <a href="#fnref_2" class="fn-hook-btn">&ldca;</a>
                def
            </li>
            <li>
                <a id="fn_3"></a>
                <a href="#fnref_3" class="fn-hook-btn">&ldca;</a>
                ghi
            </li>
        </ol>
        </div>
        
        <p>DEF</p>
        <div class="fn-defs">
        <a id="fn-defs"></a>
        <div class="fn-title">Notes</div>
        <ol>
            <li>
                <a id="fn_a_fn_4"></a>
                <a href="#fnref_a_fn_4" class="fn-hook-btn">&ldca;</a>
                klm
            </li>
            <li>
                <a id="fn_a_fn_5"></a>
                <a href="#fnref_a_fn_5" class="fn-hook-btn">&ldca;</a>
                nop
            </li>
        </ol>
        </div>
        """)
end
