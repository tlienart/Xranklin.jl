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
    tl = TestLogger(min_level=Warn)
    with_logger(tl) do
        s = """
            +++
            a = Date(2020,1,15)
            +++
            {{a}}
            """ |> html
    end
    @test contains(s, "[FAILED:]")
    @test contains(tl.logs[1].message, "UndefVarError: `Date` not defined")
    @test contains(tl.logs[2].message, "A block '{{a}}' was found but the name 'a' does not")
end
