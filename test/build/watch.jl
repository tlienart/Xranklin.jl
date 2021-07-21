include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "ignore" begin
    # helper functions
    @test X._access(r"foo") == X._access("foo") == "foo"
    @test X._isempty(r"") == X._isempty("") == true
    @test X._endswith(r"abc", 'c') == X._endswith("abc", 'c') == true
    @test X._check("aabc", r"a+bc")
    @test X._check("abc", "abc")

    lc = X.DefaultLocalContext()
    X.set_current_local_context(lc)
    X.set_paths()
    X.setvar!(lc.glob, :ignore, [r"abc/def.*/", r"foo*", "def", "/", r"\/", ""])

    f2i, d2i = X.files_and_dirs_to_ignore()
    for c in ("README.md", "def", r"foo*")
        @test c in f2i
    end
    for c in ("node_modules/", r"abc/def.*/")
        @test c in d2i
    end
    @test "/" ∉ union(f2i, d2i)
    @test r"\/" ∉ union(f2i, d2i)
    @test all(!X._isempty, f2i)
    @test all(!X._isempty, d2i)

    @test X.should_ignore(abspath("README.md"), f2i, d2i)
    @test X.should_ignore(abspath("node_modules/"), f2i, d2i)
    @test X.should_ignore(abspath("abc/defghi/"), f2i, d2i)
    @test X.should_ignore(abspath("foobar.md"), f2i, d2i)
end

@testset "addnewfile" begin
    tf = X.TrackedFiles()
    ftemp = tempname()
    write(ftemp, "Foo bar")
    mt = mtime(ftemp)
    sp = splitpath(ftemp)
    root = joinpath(sp[1:end-1]...)
    p = root => sp[end]
    X.add_if_new_file!(tf, p, false)
    @test p in keys(tf)
    @test tf[p] == mt
    pop!(tf, p)
    X.add_if_new_file!(tf, p, true)
    @test tf[p] == 0
end
