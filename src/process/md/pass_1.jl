"""
    process_md_file_pass_1(...)

[threaded] Source MD to iHTML. Ignore layout and DBB.

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
            lc::LocalContext,
            fpath::String;
            # kwargs
            allow_init_skip::Bool = false
        )::Bool

    crumbs(@fname)

    # Note: this is called from process_md_file which is
    # called from process_file which sets the cur_lc so
    # necessarily we have lc === cur_lc() here.

    __t = tic()

    prev_hash     = lc.page_hash[]
    from_cache    = !iszero(prev_hash)
    ignore_cache  = from_cache & getvar(lc, :ignore_cache, false)
    bk_state      = reset_page_context!(lc, reset_notebook=ignore_cache)
    bk_tags_dict  = get_page_tags(lc)

    # get markdown and compute hash so we can check whether the content
    # has changed (if it's been seen before).
    # NOTE: we don't use `filehash` here because we need the actual content of
    # NOTE: the page anyway, so we compute the hash after retrieving the content
    page_content_md = read(fpath, String)
    page_hash       = hash(page_content_md)
    lc.page_hash[]  = page_hash

    opath = get_opath(lc.glob, fpath)
    set_meta_parameters(lc, fpath, opath)

    skip = allow_init_skip && all((
                !ignore_cache,
                prev_hash == page_hash,
                !isempty(getvar(lc, :_generated_ihtml, ""))
           ))

    toc(__t, "mdp1 inner | cache check")

    if skip
        restore_page_context!(lc, bk_state)

    else
        # set notebook counters at the top (might already be there)
        reset_notebook_counters!(lc)

        # reset whether there's parsing / block errors
        setvar!(lc, :_has_parser_error, false)
        setvar!(lc, :_has_failed_blocks, false)

        # evaluate
        __t = tic()
        ihtml = convert_md(page_content_md, lc)
        setvar!(lc, :_generated_ihtml, ihtml)
        toc(__t, "mdp1 - convert_md")

        __t = tic()

        # Now that the page has been evaluated, we can discard entries
        # from `indep_code` mapping that are obsolete (e.g. if an indep
        # cell changed, or was removed)
        refresh_indep_code!(lc)

        # Check if any anchors were removed so that they can be removed
        # from gc.anchors later on
        setvar!(lc, :_rm_anchors, setdiff(bk_state.anchors, lc.anchors))

        # Check if a title is set, if not, take the first heading if there's
        # one; the headings are ordered so we just take the first, the 3d entry
        # is the text of the heading (see PageHeadings)
        if isempty(getvar(lc, :title, "")) && !isempty(lc.headings)
            setvar!(lc, :title, first(values(lc.headings))[3])
        end

        # Check if any tag was removed / added so it can be adjusted in
        # the gc later on
        __ti = tic()
        tags_dict   = get_page_tags(lc)
        toc(__ti, "get page tags")
        old_keys    = keys(bk_tags_dict)
        new_keys    = keys(tags_dict)
        tags_remove = setdiff(old_keys, new_keys)
        tags_add    = [id => tags_dict[id] for id in setdiff(new_keys, old_keys)]
        setvar!(lc, :_rm_tags,  tags_remove)
        setvar!(lc, :_add_tags, tags_add)

        # Check if the page activated an environment (see lx_activate), and if
        # so re-activate the "main" environment. It shouldn't be
        # necessary to instantiate it.
        bkpf = getvar(lc.glob, :project, "")
        if Pkg.project().path != bkpf
            Pkg.activate(bkpf)
        end

        toc(__t, "rest of mdp1")
    end

    return skip
end


"""
    reset_page_context!(lc; reset_notebook)

Set the current page context and reset its variables such as the headers,
equation counters etc.
The kwarg `reset_notebook` is passed in the context of `ignore_cache`.

## Return

The set of anchors from `lc` before they were reset. This will allow us to
establish whether any anchor has changed on the page and, if so, to
re-trigger pages that may depend upon those.
"""
function reset_page_context!(
            lc::LocalContext;
            reset_notebook=false
        )::NamedTuple

    state = (
        anchors   = copy(lc.anchors),
        headings  = copy(lc.headings),
        eq_cntr   = eqrefs(lc)["__cntr__"],
        fn_cntr   = fnrefs(lc)["__cntr__"],
        cell_cntr = getvar(lc, :_auto_cell_counter, 0),
        paginator = getvar(lc, :_paginator_name, ""),
        hasmath   = getvar(lc, :_hasmath),
        hascode   = getvar(lc, :_hascode),
    )

    # Reset page counters and variables (headers etc)
    empty!(lc.anchors)
    empty!(lc.headings)
    eqrefs(lc)["__cntr__"] = 0
    fnrefs(lc)["__cntr__"] = 0
    setvar!(lc, :_auto_cell_counter, 0)
    setvar!(lc, :_paginator_name, "")
    setvar!(lc, :_hasmath, false)
    setvar!(lc, :_hascode, false)

    # in the context of "ignore_cache", reset both notebooks
    reset_notebook && reset_both_notebooks!(lc)

    return state
end


"""
    restore_page_context!(lc, state)

In the "skip" case (where a page hasn't changed), we need to undo the effect
of `reset_page_context!` so that the inclusion of layout files has
access to the proper environment (which has otherwise been scrubbed).
The `state` comes from `reset_page_context!`.
"""
function restore_page_context!(
            lc::LocalContext,
            state::NamedTuple
        )::Nothing

    union!(lc.anchors,  state.anchors)
    merge!(lc.headings, state.headings)
    eqrefs(lc)["__cntr__"] = state.eq_cntr
    fnrefs(lc)["__cntr__"] = state.fn_cntr
    setvar!(lc, :_auto_cell_counter, state.cell_cntr)
    setvar!(lc, :_paginator_name, state.paginator)
    setvar!(lc, :_hascode, state.hascode)
    setvar!(lc, :_hasmath, state.hasmath)
    return
end
