include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "vars" begin
    v = X.Vars(
        :a => 1,
        :b => "hello"
    )
    @test X.getvar(v, :a, 0) == 1
    @test X.getvar(v, :b, "") == "hello"
    @test X.getvar(v, :c, 0) == 0
    @test X.getvar(v, :c) === nothing

    X.setvar!(v, :a, true)
    @test X.getvar(v, :a) === true
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
