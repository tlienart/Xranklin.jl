include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "nb-vars" begin
    lc = X.DefaultLocalContext(id="foo")
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
    X.add_vars!(lc, X.subs(v))
    @test getvar(lc, :a) == 5
    @test getvar(lc, :b) == 7
    @test X.counter(lc.nb_vars) == 2
    nb = lc.nb_vars
    @test nb.code_pairs[1].result == [:a, :b]

    # simulate re-running the page (counter reset)

    X.reset_counter!(lc.nb_vars)
    @test X.counter(lc.nb_vars) == 1
    @test length(lc.nb_vars) == 1
    # reevaluating should be instant (same hash)
    X.add_vars!(lc, X.subs(v))
    @test getvar(lc, :a) == 5
    @test getvar(lc, :b) == 7
    @test X.counter(lc.nb_vars) == 2
    @test length(lc.nb_vars) == 1

    # replacing with modified, the bindings should be eliminated
    # see remove_bindings

    v = """
        c = 3
        """
    X.reset_counter!(lc.nb_vars)
    X.add_vars!(lc, X.subs(v))

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
    X.add_vars!(lc, X.subs(v))
    @test length(lc.nb_vars) == 2
    @test getvar(lc, :a) == 3
    @test getvar(lc, :c) == 3
    @test X.counter(nb) == 3

    X.reset_notebook!(nb; ismddefs=true)
    @test length(nb) == 0
    @test X.counter(nb) == 1
    @test getvar(lc, :a) === nothing
    @test getvar(lc, :c) === nothing
    @test getvar(lc, :d) === nothing
end


@testset "nb-code" begin
    lc = X.DefaultLocalContext(id="foo")
    nb = lc.nb_code
    c = """
        a = 5
        a^2
        """
    X.add_code!(lc, X.subs(c), block_name="abc")
    @test X.counter(nb) == 2
    @test length(nb) == 1
    @test nb.code_pairs[1].result == 25

    # - simulating modification of the samecell
    X.reset_counter!(nb)
    X.add_code!(lc, X.subs(c * ";"), block_name="abc")
    @test length(nb) == 1
    @test nb.code_pairs[1].result === nothing
    @test nb.code_map["abc"] == 1

    X.add_code!(lc, X.subs("a^3"), block_name="def")
    @test X.counter(nb) == 3
    @test length(nb) == 2
    @test nb.code_pairs[2].result == 125
    @test nb.code_map["def"] == 2

    X.add_code!(lc, X.subs("@show a"), block_name="sss")
    @test X.counter(nb) == 4
    @test length(nb) == 3
    @test nb.code_pairs[3].result === nothing
    @test nb.code_map["sss"] == 3
end
