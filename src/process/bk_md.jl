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

# """
#     process_md_file(gc, rpath; kw...)
#
# Process a markdown file at `rpath` within `gc` by generating paths
# and calling `process_md_file` with full details.
# """
# function process_md_file(
#             gc::GlobalContext,
#             rpath::String;
#             kw...
#         )
#     fpath = path(:folder) / rpath
#     opath = get_opath(gc, fpath)
#     process_md_file(gc, fpath, opath; kw...)
# end
#
# """
#     process_md_file(gc, fpath, opath; initial_pass)
#
# Process a markdown file at path `fpath` with target output path `opath` within
# global context `gc`.
# """
# function process_md_file(
#             gc::GlobalContext,
#             fpath::String,
#             opath::String;
#             initial_pass::Bool=false,
#             allow_full_skip::Bool=false,
#             kw...
#         )::Nothing
#
#     crumbs(@fname, fpath)
#
#     # check if the file should be skipped
#     # 1> is the file actually still there? this is a rare case which may happen
#     #    when the processing is triggered by getvarfrom
#     if !isfile(fpath)
#         isfile(opath) && rm(opath)
#         return
#     end
#
#     # 2> if it's the initial pass, check if the file has already been processed
#     #    (if it's already in the gc children contexts); this may happen if an
#     #`   earlier file processing was triggered by getvarfrom
#     rpath = get_rpath(gc, fpath)
#
#     # otherwise process the page and write to opath if there is anything
#     # to write (if the page hasn't changed, nothing new will be written)
#     io = IOBuffer()
#     process_md_file_io!(
#         io, gc, fpath;
#         opath, initial_pass, allow_full_skip, kw...
#     )
#
#     # this early stop can happen if process_md_file_io was interrupted early
#     # see the page hash checks
#     io.size == 0 && return
#
#     # paginated or not, write the base unless there's nothing to write
#     # if there's nothing to write, there's also no pagination so we can
#     # stop early but in all cases start by cleaning up the paginated dirs
#     # so that we don't end up with spurious  dirs
#     odir = dirname(opath)
#     _cleanup_paginated(odir)
#
#     # Base
#     #   index.md     -> index.html
#     #   foo/index.md -> foo/index.html
#     #   foo/bar.md   -> foo/bar/index.html
#     open(opath, "w") do outf
#         write(outf, seekstart(io))
#     end
#
#     #
#     # PAGINATION
#     # > if there is pagination, we take the file at `opath` and
#     # rewrite it (to resolve PAGINATOR_TOKEN) n+1 time where n is
#     # the number of pages.
#     # For instance if there's a pagination with effectively 3 pages,
#     # then 4 pages will be written (the base page, then pages 1,2,3).
#     #
#     paginator_name = getvar(gc.children_contexts[rpath], :_paginator_name)
#     isempty(paginator_name) ?
#         _not_paginated(gc, rpath, odir) :
#         _paginated(gc, rpath, opath, paginator_name)
#
#     return
# end



# ------------------------------------------------------------------------

#
#
# """
#     process_md_file_io!(io, gc, fpath; kw...)
#
# Process a markdown file located at `fpath` within global context `gc` and
# write the result to the iostream `io`.
# Note that this may exit early (and leave `io` untouched) if it turns out that
# the page content has not changed with respect to when it was last seen.
# The caches are always loaded though as they may be accessed by other pages.
# """
# function process_md_file_io!(
#             io::IO,
#             gc::GlobalContext,
#             fpath::String;
#             opath::String="",
#             initial_pass::Bool=false,
#             allow_full_skip::Bool=false,
#             tohtml::Bool=true
#         )::Nothing
#
#     rpath = get_rpath(gc, fpath)
#     crumbs(@fname, rpath)
#
#     # CONTEXT
#     # -------
#     # retrieve the context from gc's children if it exists or
#     # create it if it doesn't
#     in_gc = rpath in keys(gc.children_contexts)
#     lc = in_gc ?
#           gc.children_contexts[rpath] :
#           DefaultLocalContext(gc; rpath)
#
#     off   = ifelse(is_recursive(lc), "...", "")
#     start = time();
#     initial_pass || @info """
#         $(off)⌛ [md-processing] $(hl(str_fmt(rpath), :cyan))
#         """
#
#     from_cache    = false
#     previous_hash = zero(UInt64)
#     if initial_pass && in_gc
#         from_cache    = true
#         previous_hash = lc.page_hash[]
#     end
#
#     bk_state     = reset_page_context!(lc)
#     bk_tags_dict = get_page_tags(lc)
#
#     # get markdown and compute the hash of it so that we can check whether
#     # the content has changed since the last time we saw it (if there was
#     # a last time).
#     # NOTE: we don't use `filehash` here because we need to read the page
#     # content anyway, so might as well compute the hash from it
#     page_content_md = read(fpath, String)
#     page_hash       = hash(page_content_md)
#     lc.page_hash[]  = page_hash
#
#     set_meta_parameters(lc, fpath, opath)
#
#     skip = false
#
#     if previous_hash == page_hash
#         # this is only possible if we're on the initial pass AND the
#         # LC was loaded from cache (so that in_gc is true)
#         # additionally it looks like the page hasn't changed, we just
#         # check whether the output path is there and if so we skip
#         if isfile(opath) && !initial_pass
#             @info """
#                 ⏩ page '$rpath' hasn't changed, skipping some of the conversion...
#                 """
#             skip = true
#         end
#     end
#     setvar!(lc, :_applied_base_url_prefix, "")
#
#     # reset the notebook counters at the top (they may already be there)
#     reset_notebook_counters!(lc)
#
#     # if we're in the skip case, we need to re-instate the state as it
#     # was before the call to reset_page_context
#     skip && restore_page_context!(lc, bk_state)
#
#     output     = ""
#     early_stop = false
#     if !(skip & allow_full_skip)
#         output = tohtml ?
#                     _process_md_file_html(lc, page_content_md; skip) :
#                     _process_md_file_latex(lc, page_content_md; skip)
#     else
#         early_stop = true
#     end
#
#     # only here do we know whether `ignore_cache` was set to 'true'
#     # if that's the case, reset the code notebook and re-evaluate.
#     if from_cache && getvar(lc, :ignore_cache, false)
#         reset_page_context!(lc, reset_notebook=true)
#         output = tohtml ?
#                   _process_md_file_html(lc, page_content_md) :
#                   _process_md_file_latex(lc, page_content_md)
#         early_stop = false
#     end
#
#     if early_stop && !initial_pass
#         @info """
#             ⏩⏩ also no change of context, skipping rest of the conversion...
#             """
#         return
#     end
#
#     # Now that the page has been evaluated, we can discard entries
#     # from `indep_code` mapping that are obsolete (e.g. if an indep
#     # cell changed!)
#     refresh_indep_code!(lc)
#
#     #
#     # HTML WRITE
#     #
#     write(io, output)
#
#     #
#     # ANCHORS
#     #
#     # check whether any anchor has been removed by comparing
#     # to 'bk_anchors'.
#     for id in setdiff(bk_state.anchors, lc.anchors)
#         rm_anchor(gc, id, lc.rpath)
#     end
#
#     #
#     # TAGS
#     #
#     tags_dict = get_page_tags(lc)
#
#     old_keys = keys(bk_tags_dict)
#     new_keys = keys(tags_dict)
#     # check whether any tag has been removed by comparing
#     # to 'bk_tags'
#     for id in setdiff(old_keys, new_keys)
#         rm_tag(gc, id, lc.rpath)
#     end
#     # do the opposite and add any new tags
#     # NOTE: this creates a local context for each tag page
#     for id in setdiff(new_keys, old_keys)
#         name = tags_dict[id]
#         add_tag(gc, id, name, lc.rpath)
#     end
#
#     initial_pass || @info """
#         $(off)... [md-processing] ✔ $(hl(time_fmt(time()-start)))
#         """
#     return
# end


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
    head_path = path(:folder) / getvar(lc.glob, :layout_head)::String
    if !isempty(head_path) && isfile(head_path)
        full_page_html = read(head_path, String)
    end
    # > PAGE
    full_page_html *= body_html
    # > FOOT
    foot_path = path(:folder) / getvar(lc.glob, :layout_foot)::String
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
    head_path = path(:folder) / getvar(lc.glob, :layout_head_lx)::String
    if !isempty(head_path) && isfile(head_path)
        full_page_latex = read(head_path, String)
    end
    full_page_latex *= page_content_latex
    full_page_latex *= "\n\n" * raw"\end{document}"

    return full_page_latex
end
