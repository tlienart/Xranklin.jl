"""
    generate_robots_txt(gc)

Form the `robots.txt`, if one already exists, overwrite it.

* Global var `robots_disallow`, takes a list of general disallow rules incl.
    glob paths etc. (Likely the most common use case)
* Local var `robots_disallow_page`, is a bool indicating that a specific page
    should be disallowed.
"""
function generate_robots_txt(gc::GlobalContext)::Nothing
    io = IOBuffer()
    print(io, """
        User-agent: *
        """
    )
    for e in gc.vars[:robots_disallow]
        print(io, """
            Disallow: $e
            """)
    end
    for (rp, lc) in gc.children_contexts
        if lc.vars[:robots_disallow_page]
            print(io, """
                Disallow: $(get_rurl(rp))
                """)
        end
    end
    if getvar(gc, :generate_sitemap, false)
        wurl = getvar(gc, :website_url, "")
        smap = wurl * getvar(gc, :sitemap_file, "sitemap") * ".xml"
        print(io, """
            \nSitemap: $(smap)
            """)
    end
    write(
        path(:site) / getvar(gc, :robots_file, "robots") * ".txt",
        take!(io)
    )
    return
end
