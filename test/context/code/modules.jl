include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "modulename" begin
    @test X.modulename("abc") == :__FRANKLIN_ABC
    mhash = string(X.modulename("abc", true))
    @test length(mhash) == length("__FRANKLIN_") + 7
    @test startswith(mhash, "__FRANKLIN_")
end

@testset "ismodule" begin
    @test X.ismodule(:Main)
    nm = X.newmodule(:foobar, Main)
    @test X.ismodule(:foobar)
    nm2 = X.newmodule(:barfoo, nm)
    @test X.ismodule(:barfoo, nm)
end

@testset "parent_module" begin
    p = X.parent_module(wipe=true)
    @test X.ismodule(nameof(p))
    include_string(p, "foo = 5")
    @test p.foo == 5
    p = X.parent_module(wipe=true)
    @test !isdefined(p, :foo)
end

@testset "submodule" begin
    p = X.parent_module(wipe=true)
    sm = X.submodule(:foobar)
    include_string(sm, "foo = 5")
    @test sm.foo == 5
    sm = X.submodule(:foobar; wipe=true)
    @test !isdefined(sm, :foo)
end
