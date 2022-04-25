"""
    process_md_file_pass_1(lc; allow_skip)

[THREAD] Source MD to iHTML. Ignore layout and DBB.

* input     : read .md file
* output    : ihtml stored in lc var
* shortcut  : file hasn't changed and ihtml is available in lc

Side items:
- discovery of anchors that may have been removed since last version
- discovery of tags that have been removed/added since last version

(these will be processed separately as it needs direct access to GC objects
and so is not thread safe).

Return true/false if the file was skipped.
"""
function process_md_file_pass_1(
            lc::LocalContext, fpath::String;
            allow_skip::Bool = false
        )::Bool

    prev_hash     = lc.page_hash[]
    from_cache    = !iszero(prev_hash)
    ignore_cache  = from_cache & getvar(lc, :ignore_cache, false)
    bk_state      = reset_page_context!(lc, reset_notebook=ignore_cache)
    bk_tags_dict  = get_page_tags(lc)

    # get markdown and compute hash so we can check whether the content
    # has changed (if it's been seen before).
    # NOTE: we don't use `filehash` here because we need to read the page
    # content anyway, so might as well compute the hash from the full content.
    page_content_md = read(fpath, String)
    page_hash       = hash(page_content_md)
    lc.page_hash[]  = page_hash

    opath = get_opath(fpath)
    set_meta_parameters(lc, fpath, opath)

    skip = allow_skip && all((
                !ignore_cache,
                prev_hash == page_hash,
                !isempty(getvar(lc, :_generated_ihtml, ""))
           ))

    if skip
        restore_page_context!(lc, bk_state)

    else
        # set notebook counters at the top (might already be there)
        reset_notebook_counters!(lc)

        # evaluate
        ihtml = convert_md(page_content_md, lc)
        setvar!(lc, :_generated_ihtml, ihtml)

        # Now that the page has been evaluated, we can discard entries
        # from `indep_code` mapping that are obsolete (e.g. if an indep
        # cell changed)
        refresh_indep_code!(lc)

        # Check if any anchors were removed so that they can be removed
        # from gc.anchors later on
        setvar!(lc, :_rm_anchors, setdiff(bk_state.anchors, lc.anchors))

        # Check if any tag was removed / added so it can be adjusted in
        # the gc later on
        tags_dict = get_page_tags(lc)
        old_keys  = keys(bk_tags_dict)
        new_keys  = keys(tags_dict)
        setvar!(lc, :_rm_tags,  setdiff(old_keys, new_keys))
        setvar!(lc, :_add_tags, [id => tags_dict[id] for id in setdiff(new_keys, old_keys)])
    end
    return skip
end


"""
    process_md_file_pass_2

[THREAD] iHTML to HTML. Resolve layout, DBB, pagination.
"""
function process_md_file_pass_2(
            lc::LocalContext,
            opath::String
        )::Nothing

        ihtml = getvar(lc, :_generated_ihtml, "")
        odir  = dirname(opath)
        _cleanup_paginated(odir)

        # XXX TODO XXX
        # skeleton_path = path(:folder) / getvar(lc, :layout_skeleton, "")
        # if isfile(skeleton_path)
        # end

        # ---------------------------------------------------------------------

        pgfoot_path = path(:folder) / getvar(lc, :layout_page_foot, "")
        page_foot   = isfile(pgfoot_path) ? read(pgfoot_path, String) : ""

        c_tag   = getvar(lc, :content_tag,   "")
        c_class = getvar(lc, :content_class, "")
        c_id    = getvar(lc, :content_id,    "")
        body    = ""
        if !isempty(c_tag)
            body = """
                <$(c_tag) $(attr(:class, c_class)) $(attr(:id, c_id))>
                  $ihtml
                  $page_foot
                </$(c_tag)>
                """
        else
            body = """
                $ihtml
                $page_foot
                """
        end

        head_path  = path(:folder) / getvar(lc.glob, :layout_head)::String
        full_page  = isfile(head_path) ? read(head_path, String) : ""
        full_page *= body
        foot_path  = path(:folder) / getgvar(:layout_foot)::String
        full_page *= isfile(foot_path) ? read(foot_path, String) : ""

        # ---------------------------------------------------------------------

        converted_html = html2(full_page, lc)

        open(opath, "w") do outf
            write(outf, converted_html)
        end
    return
end
