include(joinpath(@__DIR__, "..", "utils.jl"))

# use ends_with_semicolon
@testset "i121" begin
    s = """
        ```!
        x = 5 # with a ;
        ```
        """ |> html
    # output shown
    @test contains(s, "code-result")
    @test contains(s, ">5</code>")
    s = """
        ```!
        x = 5;
        ```
        """
end

# discard sandbox module from output
@testset "i122" begin
    s = """
        ```!
        struct Foo; x::Int; end
        Foo(1)
        ```
        """ |> html
    @test !contains(s, "Main.__FRANKLIN")
    @test contains(s, ">Foo(1)</code>")
end

@testset "i205" begin
    s = raw"""
       +++
       x = 5
       +++

       {{>$x}}

       {{> $x}}
       """ |> html
    @test s == "55"
end
