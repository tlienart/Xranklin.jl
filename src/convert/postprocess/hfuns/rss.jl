#
# The hfuns below correspond to the insertion of local/global variables
# after doing some postprocessing to ensure they're properly reflected in
# the RSS feed. The call to the function will precede that to the var.
#
"""
    {{rss_website_title}}

Insert the `:rss_website_title` assuming it's markdown to be converted to HTML.
"""
function hfun_rss_website_title(lc::LocalContext; tohtml=true)
    rss_website_title = getvar(lc.glob, :rss_website_title, "")
    return html(rss_website_title, lc; nop=true)
end


"""
    {{rss_website_description}}

Insert the `:rss_website_description` (`:rss_website_descr`).
"""
function hfun_rss_website_descr(lc::LocalContext; tohtml=true)
    rss_website_description = getvar(lc.glob, :rss_website_descr, "")
    return html(rss_website_description, lc)
end

"""
    {{rss_description}}

Insert the `:rss_descr` (`:rss_description`).
"""
function hfun_rss_descr(lc::LocalContext; tohtml=true)
    rss_description = getvar(lc, :rss_descr, "")
    return html(rss_description, lc)
end


"""
    {{rss_pubdate}}

Insert the `:rss_pubdate` local variable after converting it to the RFC822/1123
format required by the RSS standard.
"""
function hfun_rss_pubdate(lc::LocalContext; tohtml=true)
    pubdate = DateTime(getvar(lc, :rss_pubdate, Date(1)))
    # putting it in the RFC822/1123 format
    return Dates.format(pubdate, Dates.RFC1123Format) * " +0000"
end


"""
    {{rss_page_url}}

Page URL
"""
function hfun_rss_page_url(lc::LocalContext; tohtml=true)
    return get_full_url(lc.glob, lc.rpath)
end
