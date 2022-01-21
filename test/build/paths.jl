include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "paths" begin
    gc = X.DefaultGlobalContext()
    @test_throws AssertionError X.set_paths!(gc, "i_dont_exist")
    X.set_paths!(gc, pwd())
    @test isdir(X.path(:folder))
    @test X.path(:css) == joinpath(X.path(:folder), "_css")
    @test X.code_output_path("foo.png") == "foo.png"

    @test X.get_rpath(X.path(:folder)/"foo"/"bar.md") == "foo"/"bar.md"
end

@testset "get_opath" begin
    d = mktempdir()
    gc = X.DefaultGlobalContext()
    X.set_paths!(gc, d)
    # MD
    op = X.get_opath(d/"abc" => "def.md", :md)
    @test op == d/"__site"/"abc"/"def"/"index.html"
    # HTML
    op = X.get_opath(d/"def" => "abc.html", :html)
    @test op == d/"__site"/"def"/"abc"/"index.html"
    # special names
    op = X.get_opath(d => "index.html", :html)
    @test op == d/"__site"/"index.html"
    op = X.get_opath(d => "404.html", :html)
    @test op == d/"__site"/"404.html"
    # special folders
    op = X.get_opath(d/"_libs" => "foo.js", :infra)
    @test op == d/"__site"/"libs"/"foo.js"
    # keep path
    gc = X.DefaultGlobalContext()
    X.set_paths!(gc, d)
    X.setvar!(gc, :keep_path, ["foo/bar.html", "foo/baz.md", "blog/"])
    X.set_current_global_context(gc)
    op = X.get_opath(d/"foo" => "bar.html", :html)
    @test op == d/"__site"/"foo"/"bar.html"
    op = X.get_opath(d/"foo" => "baz.md", :md)
    @test op == d/"__site"/"foo"/"baz.html"
    op = X.get_opath(d/"blog" => "any.md", :md)
    @test op == d/"__site"/"blog"/"any.html"
end
