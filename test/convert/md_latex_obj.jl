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

@testset "command - nesting" begin
    let s = raw"""
        \newcommand{\foo}[2]{bar:#1#2}
        \newcommand{\ext}[1]{
            \foo{hello}{#1}
        }
        \ext{!}
        """
        h = html(s)
        l = latex(s)
        @test h // "<p>bar:hello!</p>"
        @test l // "bar:hello!"
    end
end

@testset "environment - basic" begin
    let s = raw"""
        \newenvironment{foo}{bar:}{:baz}
        \begin{foo}
        abc
        \end{foo}
        ABC
        """
        h = html(s)
        l = latex(s)
        @test h // "bar:abc:baz<p>ABC</p>"
        @test l // "bar:abc:baz\\par\nABC\\par"
    end
end

@testset "environment - nesting" begin
    let s = raw"""
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
        h = html(s)
        l = latex(s)
        @test h // "<p>bar-abc</p>\nzar-def-zaz<p>ghi-baz</p>"
        @test l // "bar-abc\\par\nzar-def-zaz\\par\nghi-baz\\par"
    end
end
