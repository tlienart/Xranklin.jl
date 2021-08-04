include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "global" begin
    gc = X.GlobalContext()
    @test gc isa X.Context

    X.setvar!(gc, :a, 5)
    @test getvar(gc, :a) == 5

    X.setdef!(gc, "abc", X.LxDef(0, "hello"))
    @test X.hasdef(gc, "abc") === true

    d = X.getdef(gc, "abc")
    @test d.def == "hello"

    @test isempty(gc.children_contexts)

    @test X.isglob(gc) == true
    @test X.getid(gc) == "__global"
    @test X.getglob(gc) === gc

    @test X.hasvar(gc, :a) == true
end

@testset "local" begin
    gc = X.GlobalContext()
    X.setvar!(gc, :a, 5)
    X.setvar!(gc, :b, [1, 2])
    X.setdef!(gc, "abc", X.LxDef(0, "hello"))

    lc = X.LocalContext(gc, rpath="REQ")
    X.setvar!(lc, :b, 0)

    @test getvar(lc, :a) == getvar(gc, :a)
    @test getvar(lc, :b) == 0
    @test X.hasdef(lc, "abc") === true
    @test X.getdef(lc, "abc").def == "hello"

    # dependencies
    @test lc.req_vars["__global"] == Set([:a])
    @test lc.req_lxdefs["__global"] == Set(["abc"])

    # children contexts
    @test gc.children_contexts["REQ"] === lc

    X.setvar!(lc, :b, 0)
    @test getvar(gc.children_contexts["REQ"], :b) == 0

    @test X.isglob(lc) == false
    @test X.getid(lc) == "REQ"
    @test X.getglob(lc) === gc

    X.prune_children!(gc)
    @test isempty(gc.children_contexts)
end

@testset "cur_ctx" begin
    # no current context set
    lc = X.DefaultLocalContext()
    @test X.cur_gc() === lc.glob

    @test getlvar(:lang) == getvar(lc, :lang)
    @test getgvar(:prepath) == getvar(lc.glob, :prepath) == ""

    # legacy access
    @test locvar(:lang) == getvar(lc, :lang) == "julia"
    @test globvar(:base_url_prefix) == getvar(lc.glob, :prepath) == ""

    X.setvar!(lc.glob, :prepath, "foo")
    @test globvar(:base_url_prefix) == "foo"

    @test getgvar(:prepath) == "foo"
    @test getlvar(:lang) == "julia"
    setgvar!(:prepath, "bar")
    @test getgvar(:prepath) == "bar"
    setlvar!(:lang, "python")
    @test getlvar(:lang) == "python"
end

@testset "pagevar" begin
    X.setenv(:cur_local_ctx, nothing)
    gc = X.GlobalContext()
    lc1 = X.LocalContext(gc, rpath="C1")
    X.setvar!(lc1, :a, 123)
    lc2 = X.LocalContext(gc, rpath="C2")
    X.setvar!(lc2, :b, 321)
    X.set_current_local_context(lc2)
    @test getvarfrom("C1", :a, 0) == 123
    @test getvarfrom("C2", :b, 0) == 321  # dumb but should work

    @test "C1" in keys(lc2.req_vars)
    @test lc2.req_vars["C1"] == Set([:a])

    @test pagevar("C1", :a) == 123
end
