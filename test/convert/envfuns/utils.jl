include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "custom env" begin
    lc = lc_with_utils(raw"""
        function env_hello(p)
            return "hello <$(p[1])> <$(p[2])>"
        end
        """)
    s = raw"""
        \begin{hello}{foo} ... \end{hello}
        """
    h = html(s, lc, nop=true)
    @test h // "hello <...> <foo>"
end
