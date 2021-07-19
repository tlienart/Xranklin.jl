using Xranklin, Test; X = Xranklin;

@testset "defaultglobal" begin
    gc = X.DefaultGlobalContext()
    @test gc isa X.GlobalContext
    # accessing stuff (no default here)
    @test value(gc, :autocode) === true
    # using alias
    @test value(gc, :prepath) == value(gc, :prefix) == value(gc, :base_url_prefix)
end

@testset "defaultlocal" begin
    lc = X.DefaultLocalContext()
    @test lc isa X.LocalContext
    @test value(lc, :hasmath, true) === false
end
