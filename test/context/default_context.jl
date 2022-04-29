include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "defaultglobal" begin
    gc = X.DefaultGlobalContext()
    @test gc isa X.GlobalContext
    @test gc === X.env(:cur_global_ctx)
    # accessing stuff (no default here)
    @test X.getvar(gc, :content_tag) === "div"
    # using alias
    @test X.getvar(gc, :prepath) ==
          X.getvar(gc, :prefix) ==
          X.getvar(gc, :base_url_prefix)
end

@testset "defaultlocal" begin
    lc = X.DefaultLocalContext(; rpath="loc")
    @test lc isa X.LocalContext
    @test X.getvar(lc, :_hasmath, true) === false
end
