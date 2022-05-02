include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "ignore" begin
    # helper functions
    @test X._access(r"foo") == X._access("foo") == "foo"
    @test X._isempty(r"") == X._isempty("") == true
    @test X._endswith(r"abc", 'c') == X._endswith("abc", 'c') == true
    @test X._check("aabc", r"a+bc")
    @test X._check("abc", "abc")

    lc = X.DefaultLocalContext(; rpath="loc")
    X.set_paths!(lc.glob, pwd())
    X.setvar!(lc.glob, :ignore, Xranklin.StringOrRegex[r"abc/def.*/", r"foo*", "def", "/", r"\/", ""])

    f2i, d2i = X.files_and_dirs_to_ignore(lc.glob)
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

    @test X.should_ignore(lc.glob, abspath("README.md"), f2i, d2i)
    @test !X.should_ignore(lc.glob, abspath("index.md"), f2i, d2i)
    @test X.should_ignore(lc.glob, abspath("node_modules/"), f2i, d2i)
    @test X.should_ignore(lc.glob, abspath("abc/defghi/"), f2i, d2i)
    @test X.should_ignore(lc.glob, abspath("foobar.md"), f2i, d2i)
    @test X.should_ignore(lc.glob, abspath(".DS_Store"), f2i, d2i)
    @test !X.should_ignore(lc.glob, abspath("DS_Store"), f2i, d2i)
    @test !X.should_ignore(lc.glob, abspath("fff/index.md"), f2i, d2i)
    @test X.should_ignore(lc.glob, abspath("fff/.DS_Store"), f2i, d2i)
end

@testset "addnewfile" begin
    tf = X.TrackedFiles()
    ftemp = tempname()
    write(ftemp, "Foo bar")
    mt = mtime(ftemp)
    sp = splitpath(ftemp)
    root = joinpath(sp[1:end-1]...)
    p = root => sp[end]
    # out of loop: keep mtime
    X.add_if_new_file!(tf, p, false)
    @test p in keys(tf)
    @test tf[p] == mt
    pop!(tf, p)
    # in loop, reset mtime  (+ logging)
    X.add_if_new_file!(tf, p, true)
    @test tf[p] == 0
end

@testset "findfiles" begin
    d  = mktempdir()
    mkdir(joinpath(d, "d1"))
    mkdir(joinpath(d, "_css"))
    write(joinpath(d, "d1", "a.md"), "abc")
    write(joinpath(d, "d1", "a.html"), "abc")
    write(joinpath(d, "d1", "a.png"), "abc")
    write(joinpath(d, "_css", "a.css"), "abc")
    write(joinpath(d, "config.md"), "abc")
    write(joinpath(d, "README.md"), "abc")  # ignored

    gc = X.DefaultGlobalContext()
    X.set_paths!(gc, d)

    wf = X.find_files_to_watch(gc, d)
    @test (d/"d1" => "a.md")    in keys(wf[:md])
    @test (d/"d1" => "a.html")  in keys(wf[:html])
    @test (d/"d1" => "a.png")   in keys(wf[:other])
    @test (d/"_css" => "a.css") in keys(wf[:infra])
    @test (d => "config.md")    in keys(wf[:infra])
    @test !any((d => "README.md") in keys(wf[k]) for k in keys(wf))
end
