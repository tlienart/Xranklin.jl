include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "nb-code" begin
    lc = X.DefaultLocalContext(rpath="foo")
    nb = lc.nb_code
    @test isa(nb, X.Notebook{false})
    c = """
        a = 5
        a^2
        """
    X.eval_code_cell!(lc, X.subs(c), cell_name="abc")
    @test X.counter(nb) == 2
    @test length(nb) == 1
    @test nb.code_pairs[1].result == 25

    # - simulating modification of the samecell
    X.reset_counter!(nb)
    X.eval_code_cell!(lc, X.subs(c * ";"), cell_name="abc")
    @test length(nb) == 1
    @test nb.code_pairs[1].result === nothing
    @test nb.code_map["abc"] == 1

    X.eval_code_cell!(lc, X.subs("a^3"), cell_name="def")
    @test X.counter(nb) == 3
    @test length(nb) == 2
    @test nb.code_pairs[2].result == 125
    @test nb.code_map["def"] == 2

    X.eval_code_cell!(lc, X.subs("@show a"), cell_name="sss")
    @test X.counter(nb) == 4
    @test length(nb) == 3
    @test nb.code_pairs[3].result === nothing
    @test nb.code_map["sss"] == 3
end
