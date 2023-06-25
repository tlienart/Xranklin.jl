"""
generate_rss_feeds(gc)

Form the RSS items associated with each local context attached to `gc` and
write the full feed file. Do the same for each of the tags.

Note: this only gets called if `:generate_rss` is true which only happens if
`_check_rss` has been called and returns `true`. This guarantees that
`rss_layout_head` and `rss_layout_item` point to existing files.

## Global feed

Process:
1. form the "head" by calling `html2` (only resolving dbb) on the rss head file
    using a default local context attached to `cur_gc`
2. call `form_rss_item` on every local context attached to `cur_gc` in attempted
    chronological order.
    This itself will call `html2` on the rss item file but using the actual
    local context associated with the item each time.
3. finish the buffer, extract the string, make all relative links into absolute
    links via `website_url` (which should correspond to the absolute URL
    of the landing page)

## Per-tag feeds

Assuming there are tags, the process is the same but filtering for each tag.
"""
function generate_rss_feeds(gc::GlobalContext)::Nothing
    # Get the relative path of each local context associated with gc that has
    # an rss_descr associated with it.
    # Then, get a relevant date (or fill one) and sort by date in anti-chron
    # order (newest at the top)
    rss_rpaths_with_date = [
        (rp, _rss_sort_date(c))
        for (rp, c) in gc.children_contexts
        if !isempty(getvar(c, :rss_descr, ""))
    ]
    sort!(rss_rpaths_with_date, by = x -> x[2], rev=true)
    rss_rpaths = [e[1] for e in rss_rpaths_with_date]

    # global feed takes all the paths
    head_path = path(:rss) / getvar(gc, :rss_layout_head, "")
    item_path = path(:rss) / getvar(gc, :rss_layout_item, "")
    _generate_rss_feed(
        gc, rss_rpaths, head_path, item_path
    )

    # per-tag feed takes only the paths for the tag; also there's a possibility
    # to provide a dedicated tag-head which will default to the same rss head
    # as the global feed.
    head_path = path(:rss) / getvar(gc, :rss_layout_head_tag, "")
    item_path = path(:rss) / getvar(gc, :rss_layout_item_tag, "")
    for tag_id in keys(gc.tags)
        tag_rss_rpaths = filter(rp -> rp ∈ gc.tags[tag_id].locs, rss_rpaths)
        _generate_rss_feed(
            gc, tag_rss_rpaths, head_path, item_path, tag_id
        )
    end
    return
end


"""
    _generate_rss_feed(...)

Main function to assemble the RSS feed either for the global or one of the tag
feed.

Note: no need to check whether head/item exist, see _check_rss.
"""
function _generate_rss_feed(
            gc::GlobalContext,
            rss_rpaths::Vector{String},
            head_path::String,
            item_path::String,
            tag_id::String = ""
        )::Nothing

    crumbs(@fname)

    case  = ifelse(isempty(tag_id), "global", tag_id)
    start = time(); @info """
        💡 $(hl("starting rss generation", :yellow)) [$(hl(case, :magenta))]
        """

    # 
    # Retrieve the template files and pre-process them
    #
    feed_ctx = DefaultLocalContext(gc; rpath="__rss__")
    if case != "global"
        setvar!(feed_ctx, :tag, gc.tags[tag_id].name)
    end
    head = read(head_path, String)
    head = html2(head, feed_ctx)
    head = replace(head, EMPTY_LINE_PAT => "\n", HTML_COMMENT_PAT => "")

    item = read(item_path, String)
    item = replace(item, HTML_COMMENT_PAT => "")

    #
    # Write the stream
    #
    io = IOBuffer()
    write(io, head)
    for rp in rss_rpaths
        rp_ctx = gc.children_contexts[rp]
        rp_rss = _form_rss_item(rp_ctx, item)
        write(io, rp_rss)
    end
    write(io, "</channel></rss>")

    #
    # Extract the stream and make relative links into absolute ones
    #
    website_url = getvar(gc, :website_url, "")
    full_rss    = replace(
        String(take!(io)),
        PREPATH_FIX_PAT => SubstitutionString("\\1=\\2$website_url")
    )

    #
    # write stream to file after
    #   1. adjusting the rss feed URL for tags
    #   2. getting the right outpath
    #
    feed_file_name = splitext(getvar(gc, :rss_file, "feed"))[1] * ".xml"
    tags_prefix    = getvar(gc, :tags_prefix, "tags")
    glob_url       = getvar(gc, :rss_feed_url, "")  # set by _check_config
    if case != "global"
        feed_url = replace(
            glob_url,
            feed_file_name => "$tags_prefix/$tag_id/$feed_file_name"
        )
        full_rss = replace(
            full_rss,
            glob_url => feed_url
        )
        outpath = path(:site) / tags_prefix / tag_id / feed_file_name
        mkpath(dirname(outpath))
    else
        outpath = path(:site) / feed_file_name
    end
    open(outpath, "w") do f
        write(f, full_rss)
    end

    δt = time() - start; @info """
        🏁 ... done $(hl(time_fmt(δt), :light_red))
        """
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
    _form_rss_item(lc)

Form the RSS item out of the local context `lc`.

Note: called under the assumption that 'path(:rss)/item.xml' exists.
"""
function _form_rss_item(
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
