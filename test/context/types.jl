using Xranklin, Test; X = Xranklin;

@testset "setdict" begin
    sd = X.SetDict{Symbol, String}()
    X.add!(sd, :a, "aa")
    X.add!(sd, :a, "bb")
    X.add!(sd, :b, "cc")
    X.add!(sd, :c, "bb")

    @test sd.fwd[:a] == Set(["aa", "bb"])
    @test sd.fwd[:b] == Set(["cc"])
    @test sd.fwd[:c] == Set(["bb"])

    @test sd.bwd["aa"] == Set([:a])
    @test sd.bwd["bb"] == Set([:a, :c])
    @test sd.bwd["cc"] == Set([:b])
end


@testset "vars" begin
    v = X.Vars(
        :a => 1,
        :b => "hello"
    )
    @test value(v, :a, 0) == 1
    @test value(v, :b, "") == "hello"
    @test value(v, :c, 0) == 0
    @test value(v, :c) === nothing

    X.setvar!(v, :a, true)
    @test value(v, :a) === true
end


@testset "lxdef" begin
    d = X.LxDef(0, "hello", 1, 2)
    @test X.from(d) == 1
    @test X.to(d) == 2
    @test d isa X.LxDef{String}
    d = X.LxDef(0, "hello" => "bye", 1, 2)
    @test d isa X.LxDef{Pair{String,String}}

    dc = X.pastdef(d)
    @test X.from(dc) < 0
    @test X.to(dc) < 0

    d = X.LxDef(0, "hello")
    @test X.from(d) < 0
    @test X.to(d) < 0
end
