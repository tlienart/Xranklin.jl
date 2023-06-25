#
# <?xml version="1.0" encoding="utf-8" standalone="yes" ?>
# <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
# <url>
#      <loc>http://www.example.com/</loc>
#      ?<lastmod>2005-01-01</lastmod>
#      ?<changefreq>monthly</changefreq>
#      ?<priority>0.8</priority>
# </url>
# </urlset>
#

# """
#     SiteMapItem
# """
# struct SiteMapItem
#     location::String
#     last_modification::Date
#     change_frequency::String
#     priority::Float64
# end
# function SiteMapItem(loc, modif, freq, prio)
# end


function generate_sitemap(gc::GlobalContext)::Nothing
    io = IOBuffer()
    println(io, """
        <?xml version="1.0" encoding="utf-8" standalone="yes" ?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        """
    )
    for (rp, lc) in gc.children_contexts
        # ignore 404 file(s) in sitemap
        last(splitdir(rp)) == "404.html" && continue
        if !getvar(lc, :sitemap_exclude, false)
            fp      = path(:folder) / rp
            lastmod = Date(unix2datetime(stat(fp).mtime))
            println(io, """
                <url>
                    <loc>
                      $(get_full_url(gc, rp))
                    </loc>
                    <lastmod>
                      $(lastmod)
                    </lastmod>
                    <changefreq>
                      $(getvar(lc, :sitemap_changefreq, ""))
                    </changefreq>
                    <priority>
                      $(getvar(lc, :sitemap_priority))
                    </priority>
                </url>
                """)
        end
    end
    println(io, "</urlset>")
    write(
        path(:site) / noext(getvar(gc, :sitemap_file, "sitemap")) * ".xml",
        take!(io)
    )
    return
end
