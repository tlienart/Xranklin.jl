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
    @test value(gc, :rss_feed_url, "") == "https://foo.com/feed.xml"

    nowarn()
    write(d/"config.md", """
        +++
        a = 5
        generate_rss = true
        +++
        """)
    gc = X.DefaultGlobalContext()
    @test value(gc, :rss_website_url, "") == ""
    X.process_config(gc)
    @test value(gc, :generate_rss, false) == true
    logall()
end

@testset "md file" begin
    d = mktempdir()
    X.set_paths(d)
    fpair = d => "foo.md"
    fpath = joinpath(fpair...)
    opath = X.form_output_path(fpair, :md)
    write(fpath, """
        abc `def` **ghi**
        """)
    gc = X.DefaultGlobalContext()
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
