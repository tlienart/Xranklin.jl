"""
    generate_rss(gc)

Form the RSS items associated with each local context attached to `gc` and
write the full feed file.

Note: this only gets called if `:generate_rss` is true which only happens if
`_check_rss` has been called and returns `true`. This guarantees that
`rss_layout_head` and `rss_layout_item` point to existing files.
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
    head = getvar(gc, :rss_layout_head, "")
    head = html2(read(head, String), DefaultLocalContext(gc; rpath="__rss__"))
    head = replace(head, EMPTY_LINE_PAT => "\n")
    write(io, head)

    # Get the relative path of each local context associated with gc
    # and get the relevant date (either rss_pubdate or date) then sort
    # by date in anti-chronological order
    rps = [
        (rp, _rssdate(c))
        for (rp, c) in gc.children_contexts
        if !isempty(getvar(c, :rss_descr, ""))
    ]
    sort!(rps, by=x->x[2], rev=true)

    # form the rss item for each rp and write to io
    for (rp, _) in rps
        write(io, form_rss_item(gc.children_contexts[rp]))
    end

    # finish the rss feed and write it to file
    write(io, "</channel></rss>")
    outpath = path(:site) / splitext(getvar(gc, :rss_file, "feed"))[1] * ".xml"
    open(outpath, "w") do f
        write(f, take!(io))
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
    _rssdate(c)

Internal function to get the `rss_pubdate` of a local context, fallback to the
context date if `rss_pubdate` is not defined.
"""
function _rssdate(c::LocalContext)::Date
    rd = getvar(c, :rss_pubdate, Date(1))
    rd == Date(1) || return rd
    return getvar(c, :date, Date(1))
end


"""
    form_rss_item(lc)

Form the RSS item out of the ``

Note:
Called under the assumption that 'path(:rss)/item.xml' exists.
"""
function form_rss_item(
            lc::LocalContext
        )::String

    crumbs(@fname, "from $(lc.rpath)")

    item_template = read(getvar(lc.glob, :rss_layout_item, ""), String)
    # read the template and remove comments
    item_template = replace(
        item_template,
        HTML_COMMENT_PAT => ""
    )
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
