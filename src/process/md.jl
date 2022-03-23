# ------------------------ #
# MARKDOWN FILE PROCESSING #
#
# > process_md_file
#   > process_md_file_io!
#     > reset_page_context!
#     > _process_md_file_html
#     > _process_md_file_latex
#
# ------------------------ #

"""
    process_md_file(gc, rpath; kw...)

Process a markdown file at `rpath` within `gc` by generating paths
and calling `process_md_file` with full details.
"""
function process_md_file(
            gc::GlobalContext,
            rpath::String;
            kw...
        )
    fpath = path(:folder) / rpath
    opath = get_opath(fpath)
    process_md_file(gc, fpath, opath; kw...)
end

"""
    process_md_file(gc, fpath, opath; initial_pass)

Process a markdown file at path `fpath` with target output path `opath` within
global context `gc`.
"""
function process_md_file(
            gc::GlobalContext,
            fpath::String,
            opath::String;
            initial_pass::Bool=false,
            allow_full_skip::Bool=false,
            kw...
        )::Nothing

    crumbs(@fname, fpath)

    # check if the file should be skipped
    # 1> is the file actually still there? this is a rare case which may happen
    #    when the processing is triggered by getvarfrom
    if !isfile(fpath)
        isfile(opath) && rm(opath)
        return
    end

    # 2> if it's the initial pass, check if the file has already been processed
    #    (if it's already in the gc children contexts); this may happen if an
    #`   earlier file processing was triggered by getvarfrom
    rpath = get_rpath(fpath)

    # otherwise process the page and write to opath if there is anything
    # to write (if the page hasn't changed, nothing new will be written)
    io = IOBuffer()
    process_md_file_io!(
        io, gc, fpath;
        opath, initial_pass, allow_full_skip, kw...
    )

    # this early stop can happen if process_md_file_io was interrupted early
    # see the page hash checks
    io.size == 0 && return

    # paginated or not, write the base unless there's nothing to write
    # if there's nothing to write, there's also no pagination so we can
    # stop early but in all cases start by cleaning up the paginated dirs
    # so that we don't end up with spurious  dirs
    odir = dirname(opath)
    _cleanup_paginated(odir)

    # Base
    #   index.md     -> index.html
    #   foo/index.md -> foo/index.html
    #   foo/bar.md   -> foo/bar/index.html
    open(opath, "w") do outf
        write(outf, seekstart(io))
    end

    #
    # PAGINATION
    # > if there is pagination, we take the file at `opath` and
    # rewrite it (to resolve PAGINATOR_TOKEN) n+1 time where n is
    # the number of pages.
    # For instance if there's a pagination with effectively 3 pages,
    # then 4 pages will be written (the base page, then pages 1,2,3).
    #
    paginator_name = getlvar(:_paginator_name)
    isempty(paginator_name) ?
        _not_paginated(gc, rpath, odir) :
        _paginated(gc, rpath, opath, paginator_name)

    return
end


"""
    _cleanup_paginated(odir)

Remove all `odir/k/` dirs to avoid ever having spurious such dirs.
Re-creating these dirs and the file in it takes negligible time.
"""
function _cleanup_paginated(
            odir::String
        )::Nothing

    # remove all pagination folders from odir
    # we're looking for folders that look like '/1/', '/2/' etc.
    # so their name is all numeric, does not start with 0 and
    # it's a directory --> remove
    for e in readdir(odir)
        if all(isnumeric, e) && first(e) != '0'
            dp = odir / e
            isdir(dp) && rm(dp, recursive=true)
        end
    end
    return
end


"""
    _not_paginated(gc, rpath, odir)

Handles the non-paginated case. Checks if the page was previously paginated,
if it wasn't, do nothing. Otherwise, update `gc.paginated` to reflect that
it's not paginated anymore.
"""
function _not_paginated(
            gc::GlobalContext,
            rpath::String,
            odir::String
        )::Nothing

    rpath in gc.paginated || return
    setdiff!(gc.paginated, rpath)
    return
end


"""
    _paginated(gc, rpath, opath, paginator_name)

Handles the paginated case. It takes the base file `odir/index.html` and
rewrites it to match the `/1/` case by replacing the `PAGINATOR_TOKEN`
(so `odir/index.html` and `odir/1/index.html` are identical). It then
goes on to write the other pages as needed.
"""
function _paginated(
            gc::GlobalContext,
            rpath::String,
            opath::String,
            paginator_name::String
        )::Nothing

    # recover the corresponding local context
    lc   = gc.children_contexts[rpath]
    iter = getvar(lc, Symbol(paginator_name)) |> collect
    npp  = getvar(lc, :_paginator_npp, 10)
    odir = dirname(opath)

    # how many pages?
    niter = length(iter)
    npg   = ceil(Int, niter / npp)

    # base content (contains the PAGINATOR_TOKEN)
    ctt = getvar(lc, :_generated_html, "")
    ctt = html2(ctt, lc; only=[:paginate])

    # repeatedly write the content replacing the PAGINATOR_TOKEN
    for pgi = 1:npg
        # range of items we should put on page 'pgi'
        sta_i = (pgi - 1) * npp + 1
        end_i = min(sta_i + npp - 1, niter)
        rge_i = sta_i:end_i
        # form the insertion
        ins_i = prod(String(e) for e in iter[rge_i])
        # file destination
        dst = mkpath(odir / string(pgi)) / "index.html"
        # process it in the local context
        ins_i = html(ins_i, set_recursive!(lc))
        # adjust lc
        setvar!(lc, :_relative_url, get_rurl(get_ropath(dst)))
        # form the page with inserted content
        ctt_i = replace(ctt, PAGINATOR_TOKEN => ins_i)
        setvar!(lc, :_generated_html, ctt_i)
        # write the file
        write(dst, _process_md_file_html(lc, "", skip=true))
    end
    # copy the `odir/1/index.html` (which must exist) to odir/index.html
    cp(odir / "1" / "index.html", odir / "index.html", force=true)
    return
end


# ------------------------------------------------------------------------

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

    # set it as current context in case it isn't
    set_current_local_context(lc)

    state = (
        anchors   = copy(lc.anchors),
        headings  = copy(lc.headings),
        eq_cntr   = eqrefs(lc)["__cntr__"],
        cell_cntr = getvar(lc, :_auto_cell_counter, 0),
        paginator = getvar(lc, :_paginator_name, ""),
        hasmath   = getvar(lc, :_hasmath),
        hascode   = getvar(lc, :_hascode),
    )

    # Reset page counters and variables (headers etc)
    empty!(lc.anchors)
    empty!(lc.headings)
    eqrefs(lc)["__cntr__"] = 0
    setvar!(lc, :_auto_cell_counter, 0)
    setvar!(lc, :_paginator_name, "")
    setvar!(lc, :_hasmath, false)
    setvar!(lc, :_hascode, false)

    # in the context of "ignore_cache", reset the notebook
    reset_notebook && reset_code_notebook!(lc)

    return state
end

"""
    restore_page_context!(lc, state)

In the "skip" case (where a page hasn't changed), we need to undo the effect
of `reset_page_context!` so that the inclusion of head.html and foot.html has
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
    setvar!(lc, :_auto_cell_counter, state.cell_cntr)
    setvar!(lc, :_paginator_name, state.paginator)
    setvar!(lc, :_hascode, state.hascode)
    setvar!(lc, :_hasmath, state.hasmath)
    return
end


"""
    process_md_file_io!(io, gc, fpath; kw...)

Process a markdown file located at `fpath` within global context `gc` and
write the result to the iostream `io`.
Note that this may exit early (and leave `io` untouched) if it turns out that
the page content has not changed with respect to when it was last seen.
The caches are always loaded though as they may be accessed by other pages.
"""
function process_md_file_io!(
            io::IO,
            gc::GlobalContext,
            fpath::String;
            opath::String="",
            initial_pass::Bool=false,
            allow_full_skip::Bool=false,
            tohtml::Bool=true
        )::Nothing

    crumbs(@fname, fpath)

    # path of the file relative to path(:folder)
    rpath = get_rpath(fpath)

    # CONTEXT
    # -------
    # retrieve the context from gc's children if it exists or
    # create it if it doesn't
    in_gc = rpath in keys(gc.children_contexts)
    lc = in_gc ? gc.children_contexts[rpath] : DefaultLocalContext(gc; rpath)

    from_cache    = false
    previous_hash = zero(UInt64)
    if initial_pass && in_gc
        from_cache    = true
        previous_hash = lc.page_hash[]
    end

    bk_state     = reset_page_context!(lc)
    bk_tags_dict = get_page_tags(lc)

    # get markdown and compute the hash of it so that we can check whether
    # the content has changed since the last time we saw it (if there was
    # a last time).
    # NOTE: we don't use `filehash` here because we need to read the page
    # content anyway, so might as well compute the hash from it
    page_content_md = read(fpath, String)
    page_hash       = hash(page_content_md)
    lc.page_hash[]  = page_hash

    set_meta_parameters(lc, fpath, opath)

    skip = false

    if previous_hash == page_hash
        # this is only possible if we're on the initial pass AND the
        # LC was loaded from cache (so that in_gc is true)
        # additionally it looks like the page hasn't changed, we just
        # check whether the output path is there and if so we skip
        if isfile(opath)
            @info """
                ⏩ page '$rpath' hasn't changed, skipping some of the conversion...
                """
            skip = true
        end
    end
    setvar!(lc, :_applied_base_url_prefix, "")

    # reset the notebook counters at the top (they may already be there)
    reset_notebook_counters!(lc)

    # if we're in the skip case, we need to re-instate the state as it
    # was before the call to reset_page_context
    skip && restore_page_context!(lc, bk_state)

    output     = ""
    early_stop = false
    if !(skip && allow_full_skip)
        output = tohtml ?
                    _process_md_file_html(lc, page_content_md; skip) :
                    _process_md_file_latex(lc, page_content_md; skip)
    else
        early_stop = true
    end

    # only here do we know whether `ignore_cache` was set to 'true'
    # if that's the case, reset the code notebook and re-evaluate.
    if from_cache && getvar(lc, :ignore_cache, false)
        reset_page_context!(lc, reset_notebook=true)
        output = tohtml ?
                  _process_md_file_html(lc, page_content_md) :
                  _process_md_file_latex(lc, page_content_md)
        early_stop = false
    end

    if early_stop
        @info """
            ⏩⏩ also no change of context, skipping reest of the conversion...
            """
        return
    end

    # Now that the page has been evaluated, we can discard entries
    # from `indep_code` mapping that are obsolete (e.g. if an indep
    # cell changed!)
    _refresh_indep_code!(lc)

    #
    # HTML WRITE
    #
    write(io, output)

    #
    # ANCHORS
    #
    # check whether any anchor has been removed by comparing
    # to 'bk_anchors'.
    for id in setdiff(bk_state.anchors, lc.anchors)
        rm_anchor(gc, id, lc.rpath)
    end

    #
    # TAGS
    #
    tags_dict = get_page_tags(lc)

    old_keys = keys(bk_tags_dict)
    new_keys = keys(tags_dict)
    # check whether any tag has been removed by comparing
    # to 'bk_tags'
    for id in setdiff(old_keys, new_keys)
        rm_tag(gc, id, lc.rpath)
    end
    # do the opposite and add any new tags
    # NOTE: this creates a local context for each tag page
    for id in setdiff(new_keys, old_keys)
        name = tags_dict[id]
        add_tag(gc, id, name, lc.rpath)
    end

    return
end


"""
    _process_md_file_html(lc, page_content_md; skip)

Form the full HTML of a page. This can take two main routes:

1. HEAD * CONTENT * PAGE_FOOT * FOOT
2. SKELETON(CONTENT)

In the first case, things are assembled one after the other and sequentially
joined. Elements (such as PAGE_FOOT) may be empty.

In the second case, if there is a skeleton, all other files are ignored
unless they're explicitly included in the skeleton. The skeleton indicates the
structure of the full page and indicates with {{page_content}} where the
converted content should be included.
"""
function _process_md_file_html(
            lc::LocalContext,
            page_content_md::String;
            skip=false
         )::String

    # Conversion of the content + wrap into tags if required
    page_content_html = getvar(lc, :_generated_html, "")
    if !skip || isempty(page_content_html)
        # the set_recursive means the conversion is not complete
        # it leaves all DBB to be converted later
        page_content_html = html(page_content_md, set_recursive!(lc))
        setvar!(lc, :_generated_html, page_content_html)
    end

    # Path 1 & 2, we start with the second one
    # > path 2 / skeleton
    skeleton_path = path(:folder) / getvar(lc, :layout_skeleton, "")
    if !isempty(skeleton_path) && isfile(skeleton_path)
        # inject the partially processed page content
        ct = html2(read(skeleton_path, String), lc; only=[:page_content])
        # finish the processing
        return html2(ct, lc)
    end
    # > path 1 / head * page *foot
    return _assemble_join_html(lc)
end


"""
    _assemble_join_html

HEAD * PAGE * FOOT (see `_process_md_file_html`).
"""
function _assemble_join_html(lc::LocalContext)::String
    #
    # PAGE FOOT
    #
    page_foot_path = path(:folder) / getvar(lc, :layout_page_foot, "")
    page_foot_html = ""
    if !isempty(page_foot_path) && isfile(page_foot_path)
        page_foot_html = read(page_foot_path, String)
    end

    #
    # PAGE (with PAGE FOOT)
    #
    c_tag     = getvar(lc, :content_tag,   "")
    c_class   = getvar(lc, :content_class, "")
    c_id      = getvar(lc, :content_id,    "")
    c_html    = getvar(lc, :_generated_html, "")
    body_html = ""
    if !isempty(c_tag)
        body_html = """
            <$(c_tag) $(attr(:class, c_class)) $(attr(:id, c_id))>
              $c_html
              $page_foot_html
            </$(c_tag)>
            """
    else
        body_html = """
            $c_html
            $page_foot_html
            """
    end

    #
    # HEAD * PAGE * FOOT
    #
    full_page_html = ""
    # > HEAD
    head_path = path(:folder) / getgvar(:layout_head)::String
    if !isempty(head_path) && isfile(head_path)
        full_page_html = read(head_path, String)
    end
    # > PAGE
    full_page_html *= body_html
    # > FOOT
    foot_path = path(:folder) / getgvar(:layout_foot)::String
    if !isempty(foot_path) && isfile(foot_path)
        full_page_html *= read(foot_path, String)
    end

    return html2(full_page_html, lc)
end


"""
    _process_md_file_latex

"""
function _process_md_file_latex(
            lc::LocalContext,
            page_content_md::String;
            skip=false
        )

    page_content_latex = getvar(lc, :_generated_latex, "")
    if !skip || isempty(page_content_latex)
        page_content_latex = latex(page_content_md, lc)
        setvar!(lc, :_generated_latex, page_content_latex)
    end

    full_page_latex = raw"\begin{document}" * "\n\n"
    head_path = path(:folder) / getgvar(:layout_head_lx)::String
    if !isempty(head_path) && isfile(head_path)
        full_page_latex = read(head_path, String)
    end
    full_page_latex *= page_content_latex
    full_page_latex *= "\n\n" * raw"\end{document}"

    return full_page_latex
end
