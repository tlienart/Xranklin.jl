using Xranklin, Test; X = Xranklin

@testset "paths" begin
    empty!(X.env(:paths))
    @test_throws AssertionError X.set_paths("i_dont_exist")
    X.set_paths("test")
    @test X.path(:folder) == "test"
    @test X.path(:css) == joinpath("test", "_css")
    @test X.code_output_path("foo.png") == "foo.png"
end
