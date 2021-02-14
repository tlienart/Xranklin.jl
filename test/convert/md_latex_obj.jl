@testset "command - basic" begin
    s = raw"""
        \newcommand{\foo}{bar}
        \foo
        """ |> html
    @test s // "bar"
    s = raw"""
        \newcommand{\foo}[1]{bar:#1}
        \foo{hello}
        """ |> html
    @test s // "bar:hello"
    s = raw"""
        \newcommand{\foo}[2]{bar:#1#2}
        \foo{hello}{!}
        """ |> html
    @test s // "bar:hello!"
end

@testset "command - nesting" begin
    s = raw"""
        \newcommand{\foo}[2]{bar:#1#2}
        \newcommand{\ext}[1]{
            \foo{hello}{#1}
        }
        \ext{!}
        """ |> html
    @test s // "bar:hello!"
end
