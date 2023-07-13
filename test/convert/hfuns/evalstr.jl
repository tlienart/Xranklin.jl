include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "basics" begin
    @test X.eval_str("5^2").value == 25
    @test X.eval_str("[i for i in 1:3]").value == [1,2,3]
end

@testset "hfun eval str" begin
    # conversion from e"..." --> "..."
    @test estr(raw"foo $bar") == "foo getvarfrom(:bar, \"loc\")"
    @test estr(raw"foo $bar $baz $ etc") == "foo getvarfrom(:bar, \"loc\") getvarfrom(:baz, \"loc\")  etc"
    @test estr(raw"foo($bar)") == "foo(getvarfrom(:bar, \"loc\"))"
    @test estr(raw"foo \$bar $baz") == raw"foo \$bar getvarfrom(:baz, \"loc\")"

    lc = X.DefaultLocalContext(; rpath="loc")
    s = """
        +++
        a = 5
        c1 = true
        c2 = false
        +++
        """
    html(s, lc)
    es = raw""" e"$a" """
    @test Xranklin.eval_str(lc, es).value == 5
    @test_warn_with begin
        es = raw""" e"2*$b" """
        @test !Xranklin.eval_str(lc, es).success
    end "error below was caught when attempting to run code"
    es = raw""" e"$b" """
    @test isnothing(Xranklin.eval_str(lc, es).value)
    es = raw""" e"$c2 || $c1" """
    @test Xranklin.eval_str(lc, es).value
end

@testset "i190" begin
    h = raw"""
        +++
        team = [
            (name="Alice", role="CEO"),
            (name="Bob", role="CTO"),
            (name="Jon", role="Eng")
        ]
        +++
        ~~~
        <ul>
        {{for person in team}}
            <li><strong>{{> $person.name}}</strong>: {{> $person.role}}</li>
        {{end}}
        </ul>
        ~~~
        """ |> html
    @test isapproxstr(h, """
        <ul>
        <li><strong>Alice</strong>: CEO</li>
        <li><strong>Bob</strong>: CTO</li>
        <li><strong>Jon</strong>: Eng</li>
        </ul>
        """)
end

@testset "i191" begin
    h = raw"""
        +++
        a = (b="", c="foo")
        +++
        {{isempty e"$a.c"}}
        foo
        {{else}}bar{{end}}
        """ |> html
    @test isapproxstr(h, """
        <p>bar</p>
        """)

    h = raw"""
        +++
        a = (b="", c="foo")
        +++
        {{if e"isempty($a.c)"}}
        foo
        {{else}}bar{{end}}
        """ |> html
    @test isapproxstr(h, """
        <p>bar</p>
        """)
end

@testset "with err" begin
    @test_warn_with begin
        h = raw"""
            {{isempty e"sqrt(-1)"}}
            foo
            {{else}}bar{{end}}
            """ |> html
        @test contains(h, "FAILED")
    end "error below was caught when attempting to run code ('__estr__')"
end

@testset "for with julia" begin
    s = """{{for x in !> [1,2,3,4]}}{{x}}{{end}}""" |> html
    @test s == "1234"
    s = """
        {{if > 5 > 7}}
        no
        {{else}}
        yes
        {{end}}
        """ |> html
    @test contains(s, "yes")

    s = """
        +++
        flag = false
        +++
        {{if flag}}
        no
        {{elseif > true}}
          {{isempty > []}}
            yes
          {{end}}
        {{end}}
        """ |> html
    @test contains(s, "yes")
end
