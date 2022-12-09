include(joinpath(@__DIR__, "..", "utils.jl"))

# i172
@testset "list with extra char" begin
    s = """
       * abc
       * def
       ghi [klm](mno.com).

       """
    @test isapproxstr(html(s), """
        <ul>
          <li>abc</li>
          <li>def
          ghi <a href=\"mno.com\">klm</a>.</li>
        </ul>
        """)
end
