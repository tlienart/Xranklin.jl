using Xranklin, Test; X = Xranklin;

@testset "defaultglobal" begin
    gc = X.DefaultGlobalContext()
    @test gc isa X.GlobalContext
end

@testset "defaultlocal" begin
    lc = X.DefaultLocalContext()
    @test lc isa X.LocalContext
end
