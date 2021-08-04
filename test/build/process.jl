include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "config" begin
    gc = X.DefaultGlobalContext()
    d  = mktempdir()
    X.set_paths(d)
    write(d/"config.md", """
        +++
        a = 5
        generate_rss = true
        website_url = "https://foo.com/"
        +++
        """)
    X.process_config(gc)
    @test getvar(gc, :rss_feed_url, "") == "https://foo.com/feed.xml"

    # reprocessing should be free because the definitions haven't changed and match
    # the hash and we didn't switch context so that the vars module is still the same
    X.process_config(gc)

    # setting generate_rss to true BUT not setting rss_website_url
    # --> force-setting to false (we hide the warning)
    nowarn()
    write(d/"config.md", """
        +++
        a = 5
        generate_rss = true
        +++
        """)
    gc = X.DefaultGlobalContext()
    X.set_paths(d)
    @test getvar(gc, :rss_website_url, "") == ""
    X.process_config(gc)
    @test getvar(gc, :generate_rss, true) == false
    logall()
end

@testset "Utils" begin
    gc = X.DefaultGlobalContext()
    utils = """
        a = 5
        hfun_foo() = "bar"
        hfun_bar() = "bar"
        lx_foo() = "baz"
        lx_bar() = "baz"
        """
    X.process_utils(utils, gc)
    @test Set(X.getgvar(:_utils_hfun_names))  == Set([:foo, :bar])
    @test Set(X.getgvar(:_utils_lxfun_names)) == Set([:foo, :bar])
    @test X.getgvar(:_utils_var_names) == [:a,]

    lc = X.DefaultLocalContext(gc)
    s = "utils: {{a}}, lc:{{lang}}, gc:{{rss_file}}"
    h = html(s, lc)
    @test h // "<p>utils: 5, lc:julia, gc:feed</p>"

    s = "foo: {{foo}}, bar: {{bar}}"
    h = html(s, lc)
    @test h // "<p>foo: bar, bar: bar</p>"
end


@testset "md file" begin
    d, gc = testdir()
    fpair = d => "foo.md"
    fpath = joinpath(fpair...)
    opath = X.form_output_path(fpair, :md)
    write(fpath, """
        abc `def` **ghi**
        """)
    gc = X.DefaultGlobalContext()
    X.set_paths(d)
    X.set_current_global_context(gc)
    X.process_md_file(gc, fpath, opath)
    @test isfile(opath)
    # there's no layout files so everything is empty, we just get the content
    s = read(opath, String)
    @test isapproxstr(s, """
        <div class="franklin-content">
          <p>abc <code>def</code> <strong>ghi</strong></p>
        </div>
        """)

    isdir(d/"_layout") || mkdir(d/"_layout")
    write(d/"_layout"/"head.html", """
        HEAD
        """)
    write(d/"_layout/page_foot.html", """
        PAGE_FOOT
        """)
    write(d/"_layout"/"foot.html", """
        FOOT
        """)
    X.process_md_file(gc, fpath, opath)
    s = read(opath, String)
    @test isapproxstr(s, """
        HEAD
        <div class="franklin-content">
          <p>abc <code>def</code> <strong>ghi</strong></p>
        PAGE_FOOT
        </div>
        FOOT
        """)
end


@testset "deps on glob" begin
    d, gc = testdir()
    write(d/"config.md", raw"""
        +++
        a = 5
        +++
        \newcommand{\foo}{bar}
        """)
    write(d/"pg1.md", raw"""
        {{a}}
        """)
    write(d/"pg2.md", raw"""
        \foo
        """)
    X.process_config(gc)
    X.process_md_file(gc, "pg1.md")
    X.process_md_file(gc, "pg2.md")

    @test isapproxstr(readpg("pg1.md"), """
    <div class="franklin-content">
    <p>5</p>
    </div>
    """)
    @test isapproxstr(readpg("pg2.md"), """
    <div class="franklin-content">
    <p>bar</p>
    </div>
    """)

    # Modify var of config
    write(d/"config.md", raw"""
        +++
        a = 7
        +++
        \newcommand{\foo}{bar}
        """)
    X.process_config(gc)
    @test gc.to_trigger == Set(["pg1.md"])
    empty!(gc.to_trigger)
    write(d/"config.md", raw"""
        +++
        a = 7
        +++
        \newcommand{\foo}{baz}
        """)
    X.process_config(gc)
    @test gc.to_trigger == Set(["pg2.md"])
end

@testset "cross var deps" begin
    d, gc = testdir(tag=false)
    write(d/"utils.jl", """
        hfun_geta(params) = getvarfrom(params[1], :a)
        """)
    X.process_utils(gc)
    write(d/"pg1.md", raw"""
        +++
        a = 5
        +++
        {{a}}
        """)
    write(d/"pg2.md", raw"""
        {{geta pg1.md}}
        """)
    X.process_md_file(gc, "pg1.md")
    X.process_md_file(gc, "pg2.md")
    @test readpg("pg1.md") // "<p>5</p>"
    @test readpg("pg2.md") // "<p>5</p>"

    # Modify vars on pg1 --> pg2 should be marked as trigger
    write(d/"pg1.md", """
        +++
        a = 7
        +++
        {{a}}
        """)
    X.process_md_file(gc, "pg1.md")
    @test readpg("pg1.md") // "<p>7</p>"
    @test X.cur_lc().to_trigger == Set(["pg2.md"])
end
