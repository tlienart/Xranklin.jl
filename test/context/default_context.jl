include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "defaultglobal" begin
    gc = X.DefaultGlobalContext()
    @test gc isa X.GlobalContext
    @test gc === X.env(:cur_global_ctx)
    # accessing stuff (no default here)
    @test getvar(gc, :content_tag) === "div"
    # using alias
    @test getvar(gc, :prepath) == getvar(gc, :prefix) == getvar(gc, :base_url_prefix)
end

@testset "defaultlocal" begin
    lc = X.DefaultLocalContext()
    @test lc isa X.LocalContext
    @test getvar(lc, :_hasmath, true) === false
end
