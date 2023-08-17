include(joinpath(@__DIR__, "..", "..", "utils.jl"))

RSS_HEAD = """
  <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0"
        xmlns:content="http://purl.org/rss/1.0/modules/content/"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:media="http://search.yahoo.com/mrss/"
        xmlns:atom="http://www.w3.org/2005/Atom"
        xmlns:georss="http://www.georss.org/georss">

      <channel>
        <title>
          <![CDATA[ {{rss_website_title}} {{isnotempty tag}}| {{tag}}{{end}} ]]>
        </title>
        <link> {{website_url}} </link>
        <description>
          <![CDATA[ {{rss_website_descr}} ]]>
        </description>
        <atom:link
            href="{{rss_feed_url}}"
            rel="self"
            type="application/rss+xml" />
  """
RSS_ITEM = """
  <item>
      <title>
        <![CDATA[  {{rss_title}}  ]]>
      </title>
      <link> {{rss_page_url}} </link>
      <guid> {{rss_page_url}} </guid>
      <description>
        <![CDATA[  {{rss_descr}}  ]]>
      </description>
  
      {{if rss_full_content}}
        <content:encoded>
          <![CDATA[  {{page_content}} ]]>
        </content:encoded>
      {{end}}

      <pubDate>{{rss_pubdate}}</pubDate>
  
      {{isnotempty rss_author}}
        <author> {{rss_author}} </author>
      {{end}}
      {{isnotempty author}}
        <atom:author>
          <atom:name>{{author}}</atom:name>
        </atom:author>
      {{end}}
  
      {{isnotempty rss_category}}
        <category> {{rss_category}} </category>
      {{end}}
  
      {{isnotempty rss_comments}}
        <comments> {{rss_comments}} </comments>
      {{end}}
  
      {{isnotempty rss_enclosure}}
        <enclosure> {{rss_enclosure}} </enclosure>
      {{end}}
  </item>
  """

@test_in_dir "_rss" "basic" begin
    write(FOLDER / "config.md", """
        +++
        generate_rss      = true
        website_url   = "https://foo.com"
        rss_website_title = "The Website"
        rss_website_descr = "Description for the **RSS** feed"
        rss_file          = "thefeed"
        +++
        """)
    mkpath(FOLDER / "_rss")

    write(FOLDER / "_rss" / "head.xml", RSS_HEAD)
    write(FOLDER / "_rss" / "item.xml", RSS_ITEM)
    
    write(FOLDER / "index.md", """
        Hello
        """)

    mkpath(FOLDER / "posts")
    write(FOLDER / "posts" / "a.md", """
        +++
        rss_pubdate = Dates.Date(2023, 5, 20)
        rss_title   = "Post a"
        rss_descr   = "Description of the **post** `a.md` with _markdown_."
        +++
        Hello this is post `a.md`
        """)
    write(FOLDER / "posts" / "b.md", """
        +++
        rss_title   = "Post b"
        rss_pubdate = Dates.Date(2023, 3, 15)
        rss_descr   = "Description of the **post** `b.md` with _markdown_."
        +++
        Hello this is post `b.md`
        """)
    build(FOLDER)

    r = read(FOLDER / "__site" / "thefeed.xml", String)

    @test contains(r, "<![CDATA[ The Website  ]]")
    @test contains(r, "<![CDATA[ <p>Description for the <strong>RSS</strong> feed</p>")
    @test contains(r, "<![CDATA[  <p>Description of the <strong>post</strong> <code>b.md</code> with <em>markdown</em>.</p>")
    @test contains(r, "<pubDate>Sat, 20 May 2023 00:00:00 +0000</pubDate>")
end

@test_in_dir "_rss" "basic-tags" begin
    write(FOLDER / "config.md", """
        +++
        generate_rss      = true
        website_url   = "https://foo.com"
        rss_website_title = "The Website"
        rss_website_descr = "Description for the **RSS** feed"
        +++
        """)
    mkpath(FOLDER / "_rss")

    write(FOLDER / "_rss" / "head.xml", RSS_HEAD)
    write(FOLDER / "_rss" / "item.xml", RSS_ITEM)
    
    write(FOLDER / "index.md", """
        Hello
        """)

    mkpath(FOLDER / "posts")
    write(FOLDER / "posts" / "a.md", """
        +++
        rss_pubdate = Dates.Date(2023, 5, 20)
        rss_title   = "Post a"
        rss_descr   = "Description of the **post** `a.md` with _markdown_."
        tags        = ["tag1", "tag2"]
        +++
        Hello this is post `a.md`
        """)
    write(FOLDER / "posts" / "b.md", """
        +++
        rss_title   = "Post b"
        rss_pubdate = Dates.Date(2023, 3, 15)
        rss_descr   = "Description of the **post** `b.md` with _markdown_."
        tags        = ["tag2"]
        +++
        Hello this is post `b.md`
        """)
    build(FOLDER)

    r = read(FOLDER / "__site" / "tags" / "tag1" / "feed.xml", String)

    @test contains(r, "<![CDATA[ The Website | tag1 ]]>")
    @test isfile(FOLDER / "__site" / "tags" / "tag2" / "feed.xml")
end
