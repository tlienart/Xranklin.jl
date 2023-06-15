"""
    generate_rss(gc)

Form the RSS items associated with each local context attached to `gc` and
write the full feed file.

Note: this only gets called if `:generate_rss` is true which only happens if
`_check_rss` has been called and returns `true`. This guarantees that
`rss_layout_head` and `rss_layout_item` point to existing files.

Process:
1. form the "head" by calling `html2` (only resolving dbb) on the rss head file
    using a default local context attached to `cur_gc`
2. call `form_rss_item` on every local context attached to `cur_gc` in attempted
    chronological order.
    This itself will call `html2` on the rss item file but using the actual
    local context associated with the item each time.
3. finish the buffer, extract the string, make all relative links into absolute
    links via `rss_website_url` (which should correspond to the absolute URL
    of the landing page)
"""
function generate_rss(
            gc::GlobalContext
        )::Nothing

    crumbs(@fname)

    # ---------------------------------------------
    println("")
    start = time(); @info """
        💡 $(hl("starting rss generation", :yellow))
        """
    println("")
    # ---------------------------------------------

    io   = IOBuffer()
    head = path(:rss) / getvar(gc, :rss_layout_head, "")
    head = html2(read(head, String), DefaultLocalContext(gc; rpath="__rss__"))
    head = replace(head, EMPTY_LINE_PAT => "\n")
    write(io, head)

    # Get the relative path of each local context associated with gc
    # and get the relevant date (either rss_pubdate or date) then sort
    # by date in anti-chronological order
    rps = [
        (rp, _rss_sort_date(c))
        for (rp, c) in gc.children_contexts
        if !isempty(getvar(c, :rss_descr, ""))
    ]
    sort!(rps, by=x->x[2], rev=true)

    # form the rss item for each rp and write to io
    item_template = read(path(:rss) / getvar(gc, :rss_layout_item, ""), String)
    # read the template and remove comments
    item_template = replace(
        item_template,
        HTML_COMMENT_PAT => ""
    )
    for (rp, _) in rps
        write(io, form_rss_item(gc.children_contexts[rp], item_template))
    end

    # close the rss feed
    write(io, "</channel></rss>")

    # make the relative links into absolute links
    base_url = getvar(gc, :rss_website_url)
    endswith(base_url, "index.html") && (base_url = base_url[1:end-10])
    endswith(base_url, '/') || (base_url *= '/')

    full_rss = replace(
        String(take!(io)),
        PREPATH_FIX_PAT => SubstitutionString("\\1=\\2$base_url")
    )

    # write to file
    outpath = path(:site) / splitext(getvar(gc, :rss_file, "feed"))[1] * ".xml"
    open(outpath, "w") do f
        write(f, full_rss)
    end

    # ---------------------------------------------
    println("")
    δt = time() - start; @info """
        💡 $(hl("rss generation done", :yellow)) $(hl(time_fmt(δt), :light_red))
        """
    println("")
    # ---------------------------------------------
    return
end


"""
    _rss_sort_date(c)

Internal function to get the `rss_pubdate` of a local context, fallback to the
context date if `rss_pubdate` is not defined. This is only used for sorting rss
items.
"""
function _rss_sort_date(c::LocalContext)::Date
    rd = getvar(c, :rss_pubdate, Date(1))
    rd == Date(1) || return rd
    return getvar(c, :date, Date(1))
end


"""
    form_rss_item(lc)

Form the RSS item out of the local context `lc`.

Note: called under the assumption that 'path(:rss)/item.xml' exists.
"""
function form_rss_item(
            lc::LocalContext,
            item_template::String
        )::String

    crumbs(@fname, "from $(lc.rpath)")

    # if the rss_title is not given, infer from title
    if isempty(getvar(lc, :rss_title, ""))
        setvar!(lc, :rss_title, getvar(lc, :title, ""))
    end
    # form the item, resolve `{{...}}`
    item = html2(item_template, lc)
    # remove skipped lines
    item = replace(item, EMPTY_LINE_PAT => "\n")
    # naive replacement of links by plaintext
    item = replace(item, HTML_LINK_PAT => s"\1")

    return item
end
