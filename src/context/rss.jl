"""
    generate_rss(gc)

Form the RSS Item associated with each local context attached to `gc` and
write the full feed file.
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

    # will never be empty because generate_rss guarantees that
    # rss_layout_head and rss_layout_item are present (see _check_rss)
    head = getvar(gc, :rss_layout_head, "")
    io   = IOBuffer()
    write(io, html2(read(head, String), gc))

    # Go over every lc attached to gc sorted
    # by rss_pubdate (if unset, use lc date)
    rps = [(rp, getvar(c, :date, Date(1))) for (rp, c) in gc.children_contexts]
    sort!(rps, by=x->x[2], rev=true)
    for (rp, _) in rps
        write(io, form_rss_item(gc.children_contexts[rp]))
    end
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
    form_rss_item(lc)

Form the RSS item out of the ``

Note:
Called under the assumption that 'path(:rss)/item.xml' exists.
"""
function form_rss_item(
            lc::LocalContext
        )::String

    crumbs(@fname, "from $(lc.rpath)")

    item_template = read(getvar(gc, :rss_layout_item, ""), String)
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
    item = replace(item, r"\n\n+" => "\n")
    # naive replacement of links by plaintext
    item = replace(item, HTML_LINK_PAT => s"\1")

    return item
end
