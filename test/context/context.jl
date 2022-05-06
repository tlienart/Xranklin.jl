include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "global" begin
    gc = X.GlobalContext()
    @test gc isa X.Context

    @test X.is_glob(gc)
    @test X.get_rpath(gc) == "__global__"
    @test X.get_glob(gc) === gc
    @test X.is_recursive(gc) == false
    @test X.set_recursive!(gc) === gc
    @test X.is_math(gc) == false

    @test cur_gc() === gc

    # Basic var access
    X.setvar!(gc, :a, 5)
    @test X.hasvar(gc, :a)
    @test X.getvar(gc, :a) == 5

    # Basic def access
    X.setdef!(gc, "abc", X.LxDef(0, "hello"))
    @test X.hasdef(gc, "abc") === true

    d = X.getdef(gc, "abc")
    @test d.def == "hello"

    # Misc
    @test isempty(gc.children_contexts)
    @test X.utils_module(gc) === gc.nb_code.mdl.Utils
    @test X.get_rpath(nothing) === ""
end


@testset "local" begin
    gc = X.GlobalContext()
    X.setvar!(gc, :a, 5)
    X.setvar!(gc, :b, [1, 2])
    X.setdef!(gc, "abc", X.LxDef(0, "hello"))

    lc = X.LocalContext(gc, rpath="REQ")

    @test X.is_glob(lc) == false
    @test X.get_rpath(lc) == "REQ"
    @test X.get_glob(lc) === lc.glob
    @test X.is_recursive(lc) == false
    @test X.is_math(lc) == false

    # modules_setup (see further)
    @test lc.nb_vars.mdl.get_rpath() == X.get_rpath(lc)

    # code assignment
    v = "b = 0"
    X.eval_vars_cell!(lc, X.subs(v))

    @test X.getvar(lc, :a) == X.getvar(gc, :a)
    @test X.getvar(lc, :b) == 0
    @test X.hasdef(lc, "abc") === true
    @test X.getdef(lc, "abc").def == "hello"

    # dependencies
    @test lc.req_vars["__global__"] == Set([:a])
    @test lc.req_lxdefs == Set(["abc"])

    # children contexts
    @test gc.children_contexts["REQ"] === lc

    X.setvar!(lc, :b, 0)
    @test X.getvar(gc.children_contexts["REQ"], :b) == 0

    X.set_recursive!(lc)
    @test X.is_recursive(lc)
end


@testset "get-set vars" begin
    gc = X.DefaultGlobalContext()
    lc = X.DefaultLocalContext(gc; rpath="local")

    X.setvar!(gc, :ga, 5)
    X.setvar!(lc, :la, 3)

    @test X.getvar(gc, :ga, 0) == 5
    @test X.getvar(gc, :ga) == 5
    @test X.getvar(gc, :la, 0) == 0
    @test X.getvar(gc, :la; default=0) == 0

    @test X.getvar(lc, :la) == 3
    @test X.getvar(lc, :ga) == 5
    @test :ga in lc.req_vars["__global__"]

    @test X.getvar(nothing, lc, :la) == nothing

    lc2 = X.DefaultLocalContext(gc; rpath="local2")
    X.setvar!(lc2, :lb, 4)

    @test X.getvar(lc2, lc, :lb) == 4
    @test :lb in lc.req_vars["local2"]

    # in module
    include_string(gc.nb_vars.mdl, """
        setlvar!(:foo, 0)
        setgvar!(:bar, 1)

        setgvar!(:baz, getgvar(:bar) + 1)
        setgvar!(:bat, getvarfrom(:lb, "local2"))
        """)
    @test !X.hasvar(gc, :foo)
    @test X.hasvar(gc, :bar)
    @test X.hasvar(gc, :baz)
    @test X.getvar(gc, :bar) == 1
    @test X.getvar(gc, :baz) == 2
    @test X.getvar(gc, :bat) == 4

    X.setvar!(lc2, :lc, 10)
    include_string(lc.nb_code.mdl, """
        setlvar!(:foo, 0)
        setgvar!(:bar, -1)

        setlvar!(:baz, getgvar(:bar))
        setlvar!(:bat, getvarfrom(:lc, "local2"))
        """)
    @test X.getvar(lc, :foo) == 0
    @test X.getvar(gc, :bar) == -1
    @test X.getvar(lc, :baz) == -1
    @test X.getvar(lc, :bat) == 10

    @test :lc in lc.req_vars["local2"]

    @test X.setvar!(nothing) === nothing

    # Legacy commands
    @test lc.nb_code.mdl.locvar("foo") == 0
    @test lc.nb_code.mdl.globvar("bar") == -1
    @test lc.nb_code.mdl.pagevar("local2", "lc") == 10
end


@testset "ordering" begin
    lc = X.DefaultLocalContext(; rpath="loc")
    gc = lc.glob
    X.setvar!(gc, :a, 5)
    X.setvar!(gc, :b, [1, 2])

    X.setvar!(gc, :b, 0)
    @test X.getvar(lc, :b) == 0
    @test X.getvar(lc, :a) == X.getvar(gc, :a) == 5

    lc = X.DefaultLocalContext(; rpath="loc")
    gc = lc.glob
    X.setvar!(gc, :lang, "foo")
    @test X.getvar(lc, :lang) == "foo"

    lc = X.DefaultLocalContext(; rpath="loc")
    gc = lc.glob
    X.setvar!(gc, :lang, "foo")
    X.eval_vars_cell!(lc, X.subs("""lang = "bar";"""))
    @test X.getvar(lc, :lang) == "bar"

    gc = X.GlobalContext()
    X.setvar!(gc, :a, 5)
    X.setvar!(gc, :b, [1, 2])
    X.setdef!(gc, "abc", X.LxDef(0, "hello"))
    lc = X.LocalContext(gc, rpath="REQ")
    v = "b = 0"
    X.eval_vars_cell!(lc, X.subs(v))

    @test X.getvar(lc, :a) == X.getvar(gc, :a)
    @test X.getvar(lc, :b) == 0
    @test X.hasdef(lc, "abc") === true
    @test X.getdef(lc, "abc").def == "hello"
end
