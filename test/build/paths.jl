include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "paths" begin
    gc = X.DefaultGlobalContext()
    @test_throws AssertionError X.set_paths("i_dont_exist")
    X.set_paths()
    @test isdir(X.path(:folder))
    @test X.path(:css) == joinpath(X.path(:folder), "_css")
    @test X.code_output_path("foo.png") == "foo.png"

    @test X.get_rpath(X.path(:folder)/"foo"/"bar.md") == "foo"/"bar.md"
end

@testset "form_output_path" begin
    d = mktempdir()
    gc = X.DefaultGlobalContext()
    X.set_paths(d)
    # MD
    op = X.form_output_path(d/"abc" => "def.md", :md)
    @test op == d/"__site"/"abc"/"def"/"index.html"
    # HTML
    op = X.form_output_path(d/"def" => "abc.html", :html)
    @test op == d/"__site"/"def"/"abc"/"index.html"
    # special names
    op = X.form_output_path(d => "index.html", :html)
    @test op == d/"__site"/"index.html"
    op = X.form_output_path(d => "404.html", :html)
    @test op == d/"__site"/"404.html"
    # special folders
    op = X.form_output_path(d/"_libs" => "foo.js", :infra)
    @test op == d/"__site"/"libs"/"foo.js"
    # keep path
    gc = X.DefaultGlobalContext()
    X.set_paths(d)
    X.setvar!(gc, :keep_path, ["foo/bar.html", "foo/baz.md", "blog/"])
    X.set_current_global_context(gc)
    op = X.form_output_path(d/"foo" => "bar.html", :html)
    @test op == d/"__site"/"foo"/"bar.html"
    op = X.form_output_path(d/"foo" => "baz.md", :md)
    @test op == d/"__site"/"foo"/"baz.html"
    op = X.form_output_path(d/"blog" => "any.md", :md)
    @test op == d/"__site"/"blog"/"any.html"
end
