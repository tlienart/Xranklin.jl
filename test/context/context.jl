include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "global" begin
    gc = X.GlobalContext()
    @test gc isa X.Context

    @test X.is_glob(gc)
    @test X.get_id(gc) == "__global__"
    @test X.get_glob(gc) === gc
    @test X.is_recursive(gc) == false
    @test X.set_recursive!(gc) === gc
    @test X.is_math(gc) == false

    @test cur_gc() === gc

    # Basic var access
    X.setvar!(gc, :a, 5)
    @test X.hasvar(gc, :a)
    @test getvar(gc, :a) == 5

    # Basic def access
    X.setdef!(gc, "abc", X.LxDef(0, "hello"))
    @test X.hasdef(gc, "abc") === true

    d = X.getdef(gc, "abc")
    @test d.def == "hello"

    # Misc
    @test isempty(gc.children_contexts)
end


@testset "local" begin
    gc = X.GlobalContext()
    X.setvar!(gc, :a, 5)
    X.setvar!(gc, :b, [1, 2])
    X.setdef!(gc, "abc", X.LxDef(0, "hello"))

    lc = X.LocalContext(gc, rpath="REQ")

    @test X.is_glob(lc) == false
    @test X.get_id(lc) == "REQ"
    @test X.get_glob(lc) === lc.glob
    @test X.is_recursive(lc) == false
    @test X.is_math(lc) == false

    # modules_setup (see further)
    @test lc.nb_vars.mdl.get_rpath() == X.get_id(lc)

    # code assignment
    v = "b = 0"
    X.eval_vars_cell!(lc, X.subs(v))

    @test getvar(lc, :a) == getvar(gc, :a)
    @test getvar(lc, :b) == 0
    @test X.hasdef(lc, "abc") === true
    @test X.getdef(lc, "abc").def == "hello"

    # dependencies
    @test lc.req_vars["__global__"] == Set([:a])
    @test lc.req_lxdefs == Set(["abc"])

    # children contexts
    @test gc.children_contexts["REQ"] === lc

    X.setvar!(lc, :b, 0)
    @test getvar(gc.children_contexts["REQ"], :b) == 0

    X.set_recursive!(lc)
    @test X.is_recursive(lc)
end


@testset "get-set vars" begin
    gc = X.DefaultGlobalContext()
    lc = X.DefaultLocalContext(gc; rpath="local")

    setvar!(gc, :ga, 5)
    setvar!(lc, :la, 3)

    @test getvar(gc, :ga, 0) == 5
    @test getvar(gc, :ga) == 5
    @test getvar(gc, :la, 0) == 0
    @test getvar(gc, :la; default=0) == 0

    @test getvar(lc, :la) == 3
    @test getvar(lc, :ga) == 5
    @test :ga in lc.req_vars["__global__"]

    @test getvar(nothing, lc, :la) == nothing

    lc2 = X.DefaultLocalContext(gc; rpath="local2")
    setvar!(lc2, :lb, 4)

    @test getvar(lc2, lc, :lb) == 4
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
    @test getvar(gc, :bar) == 1
    @test getvar(gc, :baz) == 2
    @test getvar(gc, :bat) == 4

    setvar!(lc2, :lc, 10)
    include_string(lc.nb_code.mdl, """
        setlvar!(:foo, 0)
        setgvar!(:bar, -1)

        setlvar!(:baz, getgvar(:bar))
        setlvar!(:bat, getvarfrom(:lc, "local2"))
        """)
    @test getvar(lc, :foo) == 0
    @test getvar(gc, :bar) == -1
    @test getvar(lc, :baz) == -1
    @test getvar(lc, :bat) == 10

    @test :lc in lc.req_vars["local2"]
end


# XXX XXX
#
#
#
#
# @testset "cur_ctx" begin
#     # no current context set
#     lc = X.DefaultLocalContext()
#     @test X.cur_gc() === lc.glob
#
#     @test getlvar(:lang) == getvar(lc, :lang)
#     @test getgvar(:prepath) == getvar(lc.glob, :prepath) == ""
#
#     # legacy access
#     @test locvar(:lang) == getvar(lc, :lang) == "julia"
#     @test globvar(:base_url_prefix) == getvar(lc.glob, :prepath) == ""
#
#     X.setvar!(lc.glob, :prepath, "foo")
#     @test globvar(:base_url_prefix) == "foo"
#
#     @test getgvar(:prepath) == "foo"
#     @test getlvar(:lang) == "julia"
#     setgvar!(:prepath, "bar")
#     @test getgvar(:prepath) == "bar"
#     setlvar!(:lang, "python")
#     @test getlvar(:lang) == "python"
# end
#
# @testset "pagevar" begin
#     X.setenv!(:cur_local_ctx, nothing)
#     gc = X.GlobalContext()
#     lc1 = X.LocalContext(gc, rpath="C1.md")
#     X.setvar!(lc1, :a, 123)
#     lc2 = X.LocalContext(gc, rpath="C2.md")
#     X.setvar!(lc2, :b, 321)
#     X.set_current_local_context(lc2)
#     @test getvarfrom(:a, "C1.md", 0) == 123
#     @test getvarfrom(:b, "C2.md", 0) == 321  # dumb but should work
#
#     @test "C1.md" in keys(lc2.req_vars)
#     @test lc2.req_vars["C1.md"] == Set([:a])
#
#     @test pagevar("C1.md", :a) == 123
# end
#
#
# @testset "ordering" begin
#     lc = X.DefaultLocalContext()
#     gc = lc.glob
#     X.setvar!(gc, :a, 5)
#     X.setvar!(gc, :b, [1, 2])
#
#     X.setvar!(gc, :b, 0)
#     @test getvar(lc, :b) == 0
#     @test getvar(lc, :a) == getvar(gc, :a) == 5
#
#     lc = X.DefaultLocalContext()
#     gc = lc.glob
#     X.setvar!(gc, :lang, "foo")
#     @test getvar(lc, :lang) == "foo"
#
#     lc = X.DefaultLocalContext()
#     gc = lc.glob
#     X.setvar!(gc, :lang, "foo")
#     X.eval_vars_cell!(lc, X.subs("""lang = "bar";"""))
#     @test getvar(lc, :lang) == "bar"
#
#     gc = X.GlobalContext()
#     X.setvar!(gc, :a, 5)
#     X.setvar!(gc, :b, [1, 2])
#     X.setdef!(gc, "abc", X.LxDef(0, "hello"))
#     lc = X.LocalContext(gc, rpath="REQ")
#     v = "b = 0"
#     X.eval_vars_cell!(lc, X.subs(v))
#
#     @test getvar(lc, :a) == getvar(gc, :a)
#     @test getvar(lc, :b) == 0
#     @test X.hasdef(lc, "abc") === true
#     @test X.getdef(lc, "abc").def == "hello"
# end
