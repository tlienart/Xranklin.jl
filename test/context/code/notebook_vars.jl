include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "nb-vars" begin
    lc = X.DefaultLocalContext(rpath="foo")
    @test isa(lc.nb_vars, X.VarsNotebook)
    @test nameof(lc.nb_vars.mdl) == X.modulename("foo_vars", true)
    @test nameof(lc.nb_code.mdl) == X.modulename("foo_code", true)
    @test length(lc.nb_vars) == 0
    @test X.counter(lc.nb_vars) == 1

    v = """
        a = 5
        b = 7
        """
    X.eval_vars_cell!(lc, X.subs(v))
    @test getvar(lc, :a) == 5
    @test getvar(lc, :b) == 7
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

@testset "nbv cache" begin
    lc = X.DefaultLocalContext()
    v1 = """
        a = 5
        b = 7
        """
    v2 = """
        c = 8
        d = a
        """
    X.eval_vars_cell!(lc, X.subs(v1))
    X.eval_vars_cell!(lc, X.subs(v2))

    @test !X.isstale(lc.nb_vars)
    @test getvar(lc, :d) == getvar(lc, :a)

    fp = tempname()
    X.serialize_notebok(lc.nb_vars, fp)
    json = JSON3.read(read(fp, String))
    @test length(json) == 2
    @test json[1]["code"] // v1
    @test json[2]["code"] // v2

    # Loading from cache
    lc2 = X.DefaultLocalContext()
    X.load_vars_cache!(lc2, fp)
    @test getvar(lc, :a) == getvar(lc2, :a)
    @test getvar(lc, :d) == getvar(lc2, :d)
    @test X.isstale(lc2.nb_vars)
end


@testset "is_easily_serializable" begin
    # Acceptable
    @test X.is_easily_serializable(5)
    @test X.is_easily_serializable("hello")
    @test X.is_easily_serializable(true)
    @test X.is_easily_serializable([1,2,3])
    @test X.is_easily_serializable([1 2; 3 4])
    @test X.is_easily_serializable(1:5)
    @test X.is_easily_serializable(Dict(:a=>5, :b=>7))
    @test X.is_easily_serializable((1,2,3))
    @test X.is_easily_serializable(([1,2,3], 2, :abc))
    @test X.is_easily_serializable(today())
    # Not acceptable
    @test !X.is_easily_serializable(LittleDict(:a=>5))
    @test !X.is_easily_serializable(x -> x)
    @test !X.is_easily_serializable(Module(:x))
    struct Foo
        a::Int
    end
    @test !X.is_easily_serializable(Foo(1))
end
