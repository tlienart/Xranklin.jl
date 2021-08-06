include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "nb-vars" begin
    lc = X.DefaultLocalContext(rpath="foo")
    @test isa(lc.nb_vars, X.VarsNotebook)
    @test nameof(lc.nb_vars.mdl) == X.modulename("foo_vars", true)
    @test nameof(lc.nb_code.mdl) == X.modulename("foo_code", true)
    @test length(lc.nb_vars) == 0
    @test X.counter(lc.nb_vars) == 1

    # -----
    # VARS
    # -----

    v = """
        a = 5
        b = 7
        """
    X.eval_vars_cell!(lc, X.subs(v))
    @test getvar(lc, :a) == 5
    @test getvar(lc, :b) == 7
    @test X.counter(lc.nb_vars) == 2
    nb = lc.nb_vars
    @test nb.code_pairs[1].vars == [:a, :b]

    # simulate re-running the page (counter reset)

    X.reset_counter!(lc.nb_vars)
    @test X.counter(lc.nb_vars) == 1
    @test length(lc.nb_vars) == 1
    # reevaluating should be instant (same hash)
    X.eval_vars_cell!(lc, X.subs(v))
    @test getvar(lc, :a) == 5
    @test getvar(lc, :b) == 7
    @test X.counter(lc.nb_vars) == 2
    @test length(lc.nb_vars) == 1

    # replacing with modified, the bindings should be eliminated
    # see remove_var_bindings

    v = """
        c = 3
        """
    X.reset_counter!(lc.nb_vars)
    X.eval_vars_cell!(lc, X.subs(v))

    @test getvar(lc, :a) === nothing
    @test getvar(lc, :b) === nothing
    @test getvar(lc, :c) == 3
    @test length(lc.nb_vars) == 1
    @test X.counter(nb) == 2

    # adding a new cell
    v = """
        a = 3
        d = 8
        """
    X.eval_vars_cell!(lc, X.subs(v))
    @test length(lc.nb_vars) == 2
    @test getvar(lc, :a) == 3
    @test getvar(lc, :c) == 3
    @test X.counter(nb) == 3
end
