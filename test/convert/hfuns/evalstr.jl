include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "hfun eval str" begin
    # conversion from e"..." --> "..."
    @test estr(raw"foo $bar") == "foo getlvar(:bar)"
    @test estr(raw"foo $bar $baz $ etc") == "foo getlvar(:bar) getlvar(:baz)  etc"
    @test estr(raw"foo($bar)") == "foo(getlvar(:bar))"
    @test estr(raw"foo \$bar $baz") == raw"foo \$bar getlvar(:baz)"

    lc = X.DefaultLocalContext()
    s = """
        +++
        a = 5
        c1 = true
        c2 = false
        +++
        """
    html(s, lc)
    es = raw""" e"$a" """
    @test Xranklin.eval_str(es) == 5
    es = raw""" e"2*$b" """
    @test Xranklin.eval_str(es) isa Xranklin.EvalStrError
    es = raw""" e"$b" """
    @test isnothing(Xranklin.eval_str(es))
    es = raw""" e"$c2 || $c1" """
    @test Xranklin.eval_str(es)
end
