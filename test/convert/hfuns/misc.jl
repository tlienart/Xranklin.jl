include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "{{html ...}}" begin
    s = """
        +++
        a = "Hello **Tom**."
        +++

        abc

        {{html a}}

        def
        """ |> html
    @test isapproxstr(s, """
        <p>abc</p>
        <p>Hello <strong>Tom</strong>.</p>
        <p>def</p>
        """)
end
