include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "command - basic" begin
    let s = raw"""
        \newcommand{\foo}{bar}
        \foo\foo
        """
        h = html(s)
        l = latex(s)
        @test h // "<p>barbar</p>"
        @test l // "barbar\\par"
    end
    let s = raw"""
        \newcommand{\foo}[1]{bar:#1}
        \foo{hello}
        """
        h = html(s)
        l = latex(s)
        @test h // "<p>bar:hello</p>"
        @test l // "bar:hello\\par"
    end
    let s = raw"""
        \newcommand{\foo}[2]{bar:#1#2}
        \foo{hello}{!}
        """
        h = html(s)
        l = latex(s)
        @test h // "<p>bar:hello!</p>"
        @test l // "bar:hello!\\par"
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
        @test l // "bar:hello!\\par"
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
        @test h // "<p>bar:abc:baz</p>\n<p>ABC</p>"
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
        @test h // "<p>bar-abc</p>\n<p>zar-def-zaz</p>\n<p>ghi-baz</p>"
        @test l // "bar-abc\\par\nzar-def-zaz\\par\nghi-baz\\par"
    end
end

@testset "dedenting braces" begin # issue #29
    s = raw"""
        \newcommand{\foo}[1]{
          ```julia
          #1
          ```
       }
       \foo{
            a = 1+1
            println(a)
        }
        """
    h = html(s, nop=true)
    @test strip(h) == "<pre><code class=\"julia\">a = 1+1\nprintln(a)</code></pre>"
end

@testset "more dedenting" begin
    lc = X.DefaultLocalContext()
    s = raw"""
        \newcommand{\coma}[2]{
            ~~~
            ABC class=#1
            ~~~
            #2
            ~~~
            DEF
            ~~~
        }
        \newcommand{\comb}[1]{
            \coma{foo}{
                ```markdown
                #1
                ```
            }
        }

        \comb{XXX}
        """
    h = html(s, nop=true)
    @test h // "ABC class=foo<pre><code class=\"markdown\">XXX</code></pre>DEF"

    s = raw"""
        \newcommand{\coma}[1]{
            #1
        }
        \newcommand{\comb}[1]{
            \coma{
                ```markdown
                #1
                ```
            }
        }

        \comb{
            X1
            X2
        }
        """
    h = html(s, nop=true)
    @test h // "<pre><code class=\"markdown\">X1\nX2</code></pre>"
end
