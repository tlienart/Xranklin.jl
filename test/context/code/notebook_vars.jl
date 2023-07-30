include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "nb-vars" begin
    lc = X.DefaultLocalContext(rpath="foo")
    @test isa(lc.nb_vars, X.VarsNotebook)
    @test nameof(lc.nb_vars.mdl) == X.modulename("foo_vars", true)

    # by default, lc code is not active
    @test X.is_dummy(lc.nb_code)

    v = """
        a = 5
        b = 7
        """
    X.eval_vars_cell!(lc, X.subs(v))
    @test X.getvar(lc, :a) == 5
    @test X.getvar(lc, :b) == 7
    @test X.counter(lc.nb_vars) == 2
    nb = lc.nb_vars
    @test nb.code_pairs[1].vars isa Vector{X.VarPair}
    @test nb.code_pairs[1].vars[1].var == :a
    @test nb.code_pairs[1].vars[1].value == 5
    @test nb.code_pairs[1].vars[2].var == :b
    @test nb.code_pairs[1].vars[2].value == 7

    # simulate re-running the page (counter reset)

    X.reset_counter!(lc.nb_vars)
    @test X.counter(lc.nb_vars) == 1
    @test length(lc.nb_vars) == 1
    # reevaluating should be instant (same hash)
    X.eval_vars_cell!(lc, X.subs(v))
    @test X.getvar(lc, :a) == 5
    @test X.getvar(lc, :b) == 7
    @test X.counter(lc.nb_vars) == 2
    @test length(lc.nb_vars) == 1

    # replacing with modified, the bindings should be eliminated
    # see remove_var_bindings

    v = """
        c = 3
        """
    X.reset_counter!(lc.nb_vars)
    X.eval_vars_cell!(lc, X.subs(v))

    @test X.getvar(lc, :a) === nothing
    @test X.getvar(lc, :b) === nothing
    @test X.getvar(lc, :c) == 3
    @test length(lc.nb_vars) == 1
    @test X.counter(nb) == 2

    # adding a new cell
    v = """
        a = 3
        d = 8
        """
    X.eval_vars_cell!(lc, X.subs(v))
    @test length(lc.nb_vars) == 2
    @test X.getvar(lc, :a) == 3
    @test X.getvar(lc, :c) == 3
    @test X.counter(nb) == 3
end
