include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "config" begin
    d  = mktempdir()
    X.set_paths(d)
    write(d/"config.md", """
        +++
        a = 5
        generate_rss = true
        website_url = "https://foo.com/"
        +++
        """)
    gc = X.DefaultGlobalContext()
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
    @test value(gc, :generate_rss, true) == false
    logall()
end
