include(joinpath(@__DIR__, "..", "utils.jl"))

@test_in_dir "_smr" "sitemap+robots" begin
    mkpath(FOLDER / "norobots")
    write(FOLDER / "config.md", """
        +++
        website_url      = "https://foo.com"
        generate_sitemap = true  # default
        generate_robots  = true  # default
        generate_rss     = false # default

        robots_disallow = ["norobots/", "foo/*.png"]
        +++
        """)

    write(FOLDER / "index.md", """
        # landing
        """)
    write(FOLDER / "norobots" / "abc.md", """
        # ABC
        Foo bar
        """)
    write(FOLDER / "foo.md", """
        +++
        robots_disallow_page = true
        +++
        # Foo
        """)
    write(FOLDER / "404.html", """
        Some content for the 404
        """)
    build(FOLDER)

    sitemap = FOLDER / "__site" / "sitemap.xml"
    robots  = FOLDER / "__site" / "robots.txt"
    feed    = FOLDER / "__site" / "feed.xml"
    
    @test isfile(sitemap)
    @test isfile(robots)
    @test !isfile(feed)

    @test isapproxstr(read(robots, String), """
        User-agent: *
        Disallow: norobots/
        Disallow: foo/*.png
        Disallow: /foo/

        Sitemap: https://foo.com/sitemap.xml
        """)

    smap = read(sitemap, String)
    for e in [
        "https://foo.com/norobots/abc/index.html",
        "https://foo.com/index.html",
        string(Dates.today()),
    ]
        @test contains(smap, e)
    end
    @test isfile(FOLDER / "__site" / "404.html")
    @test !contains(smap, "https://foo.com/404.html")
end
