include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "var assignment errors" begin
    s = """
        +++
        a = Dates.Date(2020,1,15)
        +++
        {{a}}
        """ |> html
    @test contains(s, "2020-01-15")

    # next one will fail because `Dates` is imported not used.
    s = """
        +++
        a = Date(2020,1,15)
        +++
        {{a}}
        """ |> html
    @test contains(s, "[FAILED:]")
end
