include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "newcommand" begin
    s = raw"""
        abc \newcommand{\foo}{bar} def
        """
    c = X.DefaultLocalContext(; rpath="loc")
    h = html(s, c)
    @test isapproxstr(h, "<p>abc def</p>")
    @test length(keys(c.lxdefs) |> collect) == 1
    d = c.lxdefs["foo"]
    @test d isa X.LxDef{String}
    @test d.nargs == 0
    @test d.def == "bar"
    @test d.from > 0
    @test d.to > d.from

    s = raw"""
        abc \newcommand{\foo}[1]{bar} def
        """
    c = X.DefaultLocalContext(; rpath="loc")
    h = html(s, c)
    @test isapproxstr(h, "<p>abc def</p>")
    @test length(keys(c.lxdefs)|>collect) == 1
    d = c.lxdefs["foo"]
    @test d.nargs == 1

    s = raw"""
        abc \newcommand{\foo}[ 1] {bar} def
        """
    c = X.DefaultLocalContext(; rpath="loc")
    h = html(s, c)
    @test isapproxstr(h, "<p>abc def</p>")
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
    c = X.DefaultLocalContext(;rpath="loc")
    h = html(s, c)
    @test isapproxstr(h, "<p>abc\n\ndef</p>")
    d = c.lxdefs["foo"]
    @test d.def == "bar\n  biz\n    boz\nbaz"
end


@testset "newenvironment" begin
    s = raw"""
        abc \newenvironment{foo}{bar}{baz} def
        """
    c = X.DefaultLocalContext(; rpath="loc")
    h = html(s, c)
    @test h // "<p>abc  def</p>"
    d = c.lxdefs["foo"]
    @test d isa X.LxDef{Pair{String,String}}
    @test d.def == ("bar" => "baz")
    @test d.nargs == 0

    s = raw"""
        abc \newenvironment{foo}[1]{bar}{baz} def
        """
    c = X.DefaultLocalContext(; rpath="loc")
    h = html(s, c)
    d = c.lxdefs["foo"]
    @test d.nargs == 1
end


@testset "new* issues" begin
    # not enough braces
    warn_msg = "Not enough braces found after a \\newcommand or \\newenvironment."

    s = raw"""
        a \newcommand{foo}
        """
    c = X.LocalContext(;rpath="l");
    
    h = html_warn(s, c; warn=warn_msg)
    @test isempty(c.lxdefs)
    @test h // raw"""
        <p>a <span style="color:red;">[FAILED:]&gt;\newcommand{foo}&lt;</span></p>
        """

    s = raw"""
        a \newenvironment{foo}{bar} b
        """
    c = X.LocalContext(;rpath="l")
    h = html_warn(s, c; warn=warn_msg)
    @test isempty(c.lxdefs)
    @test h // raw"""
        <p>a <span style="color:red;">[FAILED:]&gt;\newenvironment{foo}{bar}&lt;</span> b</p>
        """

    # nargs block incorrect
    s = raw"""\newcommand{\bar} 2{hello}"""
    c = X.LocalContext(;rpath="l")
    h = html_warn(s, c; warn=r".*following the naming brace.*")
    @test isempty(c.lxdefs)
    @test h // raw"""
        <p><span style="color:red;">[FAILED:]&gt;\newcommand{\bar}&lt;</span> 2{hello}</p>
        """
end
