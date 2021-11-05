include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "if basic" begin
    lc = X.DefaultLocalContext()
    s = raw"""
        +++
        a = true
        b = false
        +++
        {{if a}}
        foo
        {{end}}
        {{if e"$a && true"}}
        bar
        {{end}}
        {{if e"!$b"}}
        baz
        {{end}}
        {{if b}}
        not baz
        {{end}}
        """
    h = html(s, lc, nop=true)
    @test isapproxstr(h, """
        foo
        bar
        baz
        """)
end


@testset "if branch" begin
    s = raw"""
        +++
        a = true
        b = false
        +++
        {{if b}}
        foo
        {{elseif a}}
        bar
        {{end}}
        """
    h = html(s, nop=true)
    @test isapproxstr(h, "bar")
end

@testset "if nesting" begin
    s = raw"""
        +++
        a = true
        b = false
        +++
        {{if a}}
          {{if b}}
          foo
          {{else}}
          bar
          {{end}}
        {{end}}
        """
    h = html(s, nop=true)
    @test isapproxstr(h, "bar")
end
