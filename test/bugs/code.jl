include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "i121" begin
    s = """
        ```!
        x = 5 # with a ;
        ```
        """ |> html
    @test contains(s, "code-result")
    @test contains(s, ">5</code>")
end
