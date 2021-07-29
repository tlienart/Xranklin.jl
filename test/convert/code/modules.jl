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
    vm = X.vars_module()
    @test X.ismodule(nameof(vm), p)
    include_string(X.softscope, vm, "a = 7")
    vm2 = X.vars_module()
    @test vm2.a == 7
    vm3 = X.vars_module(wipe=true)
    @test !isdefined(vm3, :a)
end
