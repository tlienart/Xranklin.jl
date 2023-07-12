include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "config" begin
    gc = X.DefaultGlobalContext()
    d  = mktempdir()
    X.set_paths!(gc, d)
    rss_head = tempname()
    write(rss_head, "foo")
    rss_item = tempname()
    write(rss_item, "bar")
    write(d/"config.md", """
        +++
        a = 5
        generate_rss = true
        rss_layout_head = "$rss_head"
        rss_layout_item = "$rss_item"
        website_url = "https://foo.com/"
        +++
        """)
    X.process_config(gc)
    @test X.getvar(gc, :rss_feed_url, "") == "https://foo.com/feed.xml"

    # setting generate_rss to true BUT not setting rss_website_url
    # --> force-setting to false (we hide the warning)
    write(d/"config.md", """
        +++
        a = 5
        generate_rss = true
        +++
        """)
    gc = X.DefaultGlobalContext()
    X.set_paths!(gc, d)
    @test X.getvar(gc, :website_url, "abc") == ""
    X.process_config(gc)
    @test X.getvar(gc, :generate_rss, true) == false
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
    X.process_utils(gc, utils)
    @test Set(X.getvar(gc, :_utils_hfun_names))  == Set([:foo, :bar])
    @test Set(X.getvar(gc, :_utils_lxfun_names)) == Set([:foo, :bar])
    @test X.getvar(gc, :_utils_var_names) == [:a,]

    lc = X.DefaultLocalContext(gc; rpath="loc")
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
    opath = X.get_opath(gc, fpair, :md)
    write(fpath, """
        abc `def` **ghi**
        """)
    gc = X.DefaultGlobalContext()
    X.set_paths!(gc, d)
    X.set_current_global_context(gc)

    rpath = X.get_rpath(gc, fpath)
    lc = X.DefaultLocalContext(gc; rpath)
    X.process_md_file(lc, fpath, opath)
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
    X.set_paths!(gc, d)
    X.process_md_file(lc, fpath, opath)
    lc = X.DefaultLocalContext(gc; rpath)
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
        r: {{a}}
        """)
    write(d/"pg2.md", raw"""
        r: \foo
        """)
    X.process_config(gc)
    X.process_md_file(gc, "pg1.md")
    X.process_md_file(gc, "pg2.md")

    @test isapproxstr(readpg("pg1.md"), """
    <div class="franklin-content">
    <p>r: 5</p>
    </div>
    """)
    @test isapproxstr(readpg("pg2.md"), """
    <div class="franklin-content">
    <p>r: bar</p>
    </div>
    """)
end

@testset "cross var deps" begin
    d, gc = testdir(tag=false)
    write(d/"utils.jl", """
        hfun_geta(params) = string(getvarfrom(:a, params[1]))
        """)
    X.process_utils(gc)
    write(d/"pg1.md", raw"""
        +++
        a = 5
        +++
        r: {{a}}
        """)
    write(d/"pg2.md", raw"""
        r: {{geta pg1.md}}
        """)
    X.process_md_file(gc, "pg1.md")
    X.process_md_file(gc, "pg2.md")
    @test readpg("pg1.md") // "<p>r: 5</p>"
    @test readpg("pg2.md") // "<p>r: 5</p>"

    # Modify vars on pg1 --> pg2 should be marked as trigger
    write(d/"pg1.md", """
        +++
        a = 7
        +++
        r: {{a}}
        """)
    X.process_md_file(gc, "pg1.md")
    @test readpg("pg1.md") // "<p>r: 7</p>"
end
