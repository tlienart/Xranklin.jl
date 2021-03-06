@testset "command - basic" begin
    let s = raw"""
        \newcommand{\foo}{bar}
        \foo\foo
        """
        h = html(s)
        l = latex(s)
        @test h // "<p>barbar</p>"
        @test l // "barbar"
    end
    let s = raw"""
        \newcommand{\foo}[1]{bar:#1}
        \foo{hello}
        """
        h = html(s)
        l = latex(s)
        @test h // "<p>bar:hello</p>"
        @test l // "bar:hello"
    end
    let s = raw"""
        \newcommand{\foo}[2]{bar:#1#2}
        \foo{hello}{!}
        """
        h = html(s)
        l = latex(s)
        @test h // "<p>bar:hello!</p>"
        @test l // "bar:hello!"
    end
end


# XXX continue with latex tests


@testset "command - nesting" begin
    s = raw"""
        \newcommand{\foo}[2]{bar:#1#2}
        \newcommand{\ext}[1]{
            \foo{hello}{#1}
        }
        \ext{!}
        """
    sh = s |> html
    @test sh // "<p>bar:hello!</p>"
    sl = s |> latex
    @test sl // "bar:hello!"
end

@testset "environment - basic" begin
    s = raw"""
        \newenvironment{foo}{bar:}{:baz}
        \begin{foo}
        abc
        \end{foo}
        ABC
        """ |> html
    @test s // "bar:abc:baz<p>ABC</p>"
    s = raw"""
        \newenvironment{foo}[2]{bar/#1/}{/#2/baz}
        \begin{foo}{A}{B}
        abc
        \end{foo}
        """ |> html
    @test s // "bar/A/abc/B/baz"
end

@testset "environment - nesting" begin
    s = raw"""
        \newenvironment{foo}{bar-}{-baz}
        \newenvironment{fooz}{zar-}{-zaz}
        \begin{foo}
            abc
            \begin{fooz}
                def
            \end{fooz}
            ghi
        \end{foo}
        """
    sh = s |> html
    @test sh // "<p>bar-abc</p>\nzar-def-zaz<p>ghi-baz</p>"
    sl = s |> latex
    @test sl // "bar-abc\\par\nzar-def-zaz\\par\nghi-baz\\par"
end
