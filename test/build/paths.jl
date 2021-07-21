include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "paths" begin
    empty!(X.env(:paths))
    @test_throws AssertionError X.set_paths("i_dont_exist")
    X.set_paths()
    @test isdir(X.path(:folder))
    @test X.path(:css) == joinpath(X.path(:folder), "_css")
    @test X.code_output_path("foo.png") == "foo.png"
end
