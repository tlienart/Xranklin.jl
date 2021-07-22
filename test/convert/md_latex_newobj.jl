include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "newcommand" begin
    s = raw"""
        abc \newcommand{\foo}{bar} def
        """
    c = X.LocalContext()
    h = html(s, c)
    @test isapproxstr(h, "<p>abc</p>\n  <p>def</p>")
    @test length(c.lxdefs.keys) == 1
    d = c.lxdefs["foo"]
    @test d isa X.LxDef{String}
    @test d.nargs == 0
    @test d.def == "bar"
    @test d.from > 0
    @test d.to > d.from

    s = raw"""
        abc \newcommand{\foo}[1]{bar} def
        """
    c = X.LocalContext()
    h = html(s, c)
    @test isapproxstr(h, "<p>abc</p>\n  <p>def</p>")
    @test length(c.lxdefs.keys) == 1
    d = c.lxdefs["foo"]
    @test d.nargs == 1

    s = raw"""
        abc \newcommand{\foo}[ 1] {bar} def
        """
    c = X.LocalContext()
    h = html(s, c)
    @test isapproxstr(h, "<p>abc</p>\n  <p>def</p>")
    @test length(c.lxdefs.keys) == 1
    d = c.lxdefs["foo"]
    @test d.nargs == 1

    s = raw"""
        abc
        \newcommand{\foo}[1 ]{
            bar
              biz
                boz
            baz
        }
        def
        """
    c = X.LocalContext()
    h = html(s, c)
    @test isapproxstr(h, "<p>abc</p>\n  <p>def</p>")
    d = c.lxdefs["foo"]
    @test d.def == "bar\n  biz\n    boz\nbaz"
end

@testset "newenvironment" begin
    s = raw"""
        abc \newenvironment{foo}{bar}{baz} def
        """
    c = X.LocalContext()
    h = html(s, c)
    @test isapproxstr(h, "<p>abc</p>\n  <p>def</p>")
    d = c.lxdefs["foo"]
    @test d isa X.LxDef{Pair{String,String}}
    @test d.def == ("bar" => "baz")
    @test d.nargs == 0

    s = raw"""
        abc \newenvironment{foo}[1]{bar}{baz} def
        """
    c = X.LocalContext()
    h = html(s, c)
    d = c.lxdefs["foo"]
    @test d.nargs == 1
end


@testset "new* issues" begin
    Logging.disable_logging(Logging.Warn)
    # not enough braces
    s = raw"""
        a \newcommand{foo}
        """
    c = X.LocalContext(); h = html(s, c)
    @test isempty(c.lxdefs)
    @test isapproxstr(h, """
        <p>a</p>
        <span style="color:red">[FAILED:]&gt;\\newcommand&lt;</span>
        <p>{foo}</p>
        """)

    s = raw"""
        a \newenvironment{foo}{bar} b
        """
    c = X.LocalContext(); h = html(s, c)
    @test isempty(c.lxdefs)
    @test isapproxstr(h, """
        <p>a</p>
        <span style="color:red">[FAILED:]&gt;\\newenvironment&lt;</span>
        <p>{foo}{bar} b</p>
        """)

    # nargs block incorrect
    s = raw"""\newcommand{\bar} 2{hello}"""
    c = X.LocalContext(); h = html(s, c)
    @test isempty(c.lxdefs)
    @test isapproxstr(h, """
        <span style="color:red">[FAILED:]&gt;\\newcommand&lt;</span>
        <p>{\\bar} 2{hello}</p>
        """)
    Logging.disable_logging(Logging.Debug)
end
