using Xranklin, Test; X = Xranklin;

@testset "global" begin
    gc = X.GlobalContext()
    @test gc isa X.Context

    X.setvar!(gc, :a, 5)
    @test value(gc, :a) == 5

    X.setdef!(gc, "abc", X.LxDef(0, "hello"))
    @test X.hasdef(gc, "abc") === true

    d = X.getdef(gc, "abc")
    @test d.def == "hello"
end

@testset "local" begin
    gc = X.GlobalContext()
    X.setvar!(gc, :a, 5)
    X.setvar!(gc, :b, [1, 2])
    X.setdef!(gc, "abc", X.LxDef(0, "hello"))

    lc = X.LocalContext(gc, id="REQ")
    X.setvar!(lc, :b, 0)

    @test value(lc, :a) == value(gc, :a)
    @test value(lc, :b) == 0
    @test X.hasdef(lc, "abc") === true
    @test X.getdef(lc, "abc").def == "hello"

    # dependencies
    @test lc.req_glob_vars == Set([:a])
    @test lc.req_glob_lxdefs == Set(["abc"])

    @test gc.vars_deps.fwd[:a] == Set(["REQ"])
    @test gc.lxdefs_deps.fwd["abc"] == Set(["REQ"])

    # now the page doesn't require anything from global
    lc = X.LocalContext(gc, id="REQ")
    X.refresh_global_context!(lc)
    @test isempty(gc.vars_deps.fwd[:a])
    @test isempty(gc.vars_deps.bwd["REQ"])
    @test isempty(gc.lxdefs_deps.fwd["abc"])
    @test isempty(gc.lxdefs_deps.bwd["REQ"])
end
