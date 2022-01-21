# ------------------------ #
# MARKDOWN FILE PROCESSING #
#
# > process_md_file
#   > process_md_file_io!
#     > setup_page_context
#     > _process_md_file_html
#     > _process_md_file_latex
#
# ------------------------ #

"""
    process_md_file(gc, rpath; kw...)

Process a markdown file at `rpath` within `gc` by generating paths
and calling `process_md_file` with full details.
"""
function process_md_file(gc::GlobalContext, rpath::String; kw...)
    crumbs("process_md_file", rpath)
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
            kw...)::Nothing

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
    in_gc = rpath in keys(gc.children_contexts)
    if initial_pass && in_gc
        @debug "🚀 skipping $rpath (page already processed)."
        return
    end

    # otherwise process the page and write to opath if there is anything
    # to write (if the page hasn't changed, nothing new will be written)
    io = IOBuffer()
    process_md_file_io!(
        io, gc, fpath;
        opath, initial_pass, in_gc, kw...
    )

    if io.size == 0
        return
    else
        open(opath, "w") do outf
            write(outf, seekstart(io))
        end
    end
    return
end


"""
    setup_page_context(lc; reset_notebook)

Set the current page context and reset its variables such as the headers,
equation counters etc.
The kwarg `reset_notebook` is passed in the context of `ignore_cache`.

## Return

The vector of anchors from `lc` before it was reset. This will allow us to
establish whether anchors have changed on the page and, if so, to re-trigger
pages that may depend upon those enchors.
"""
function setup_page_context(lc::LocalContext; reset_notebook=false)::Set{String}
    # set it as current context in case it isn't
    set_current_local_context(lc)
    bk_anchors = copy(lc.anchors)

    # Reset page counters and variables (headers etc)
    empty!(lc.headers)
    empty!(lc.anchors)
    eqrefs(lc)["__cntr__"] = 0
    setvar!(lc, :_auto_cell_counter, 0)

    # in the context of "ignore_cache", reset the notebook
    reset_notebook && reset_code_notebook!(lc)

    return bk_anchors
end


"""
    process_md_file_io!(io, gc, fpath, opath)

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
            in_gc::Bool=false,
            tohtml::Bool=true
            )::Nothing
    crumbs("process_md_file_io!", fpath)

    # path of the file relative to path(:folder)
    rpath  = get_rpath(fpath)
    ropath = get_ropath(opath)

    # CONTEXT
    # -------
    # retrieve the context from gc's children if it exists or
    # create it if it doesn't
    lc = in_gc ?
            gc.children_contexts[rpath] :
            DefaultLocalContext(gc; rpath)

    bk_anchors = setup_page_context(lc)

    # get markdown and compute the hash of it so that we can check whether
    # the content has changed since the last time we saw it (if there was
    # a last time).
    page_content_md = read(fpath, String)
    page_hash       = hash(page_content_md)

    # if we're in the initial pass, there may be cached representation of
    # the hash of the page, of the vars and of the code notebooks that can
    # be loaded and leveraged.
    initial_cache_used = false
    if initial_pass
        bp  = path(:cache) / noext(rpath)
        fpv = bp / "nbv.cache"
        fpc = bp / "nbc.cache"
        pgc = bp / "pg.hash"

        if isfile(fpv)
            load_vars_cache!(lc, fpv)
            initial_cache_used = true
        end

        if isfile(fpc)
            load_code_cache!(lc, fpc)
            initial_cache_used = true
        end

        # page hasn't changed since last time --> early stop
        if isfile(pgc) && (read(pgc, UInt64) == page_hash) && isfile(opath)
            lc.page_hash[] = page_hash
            @info """
                👀 page '$rpath' hasn't changed, skipping the conversion...
                """
            return
        end
    else
        # reset the notebook counters at the top
        reset_notebook_counters!(lc)
    end

    # set meta parameters
    s = stat(fpath)
    setvar!(lc, :_relative_path, rpath)
    setvar!(lc, :_relative_url, unixify(ropath))
    setvar!(lc, :_creation_time, s.ctime)
    setvar!(lc, :_modification_time, s.mtime)

    lc.page_hash[] = page_hash

    output = (tohtml ?
                _process_md_file_html(lc, page_content_md) :
                _process_md_file_latex(lc, page_content_md))::String

    # only here do we know whether `ignore_cache` was set to 'true'
    # if that's the case, reset the code notebook and re-evaluate.
    if initial_cache_used && getvar(lc, :ignore_cache, false)
        setup_page_context(lc, reset_notebook=true)
        output = (tohtml ?
                    _process_md_file_html(lc, page_content_md) :
                    _process_md_file_latex(lc, page_content_md))::String
    end

    write(io, output)

    # check whether any anchor has been removed by comparing
    # to 'bk_anchors'.
    for id in setdiff(bk_anchors, lc.anchors)
        rm_anchor(gc, id, lc.rpath)
    end
    return
end

"""
    _process_md_file_html
"""
function _process_md_file_html(ctx::LocalContext, page_content_md::String)
    # get and process html for the foot of the page
    page_foot_path = path(:folder) / getgvar(:layout_page_foot)::String
    page_foot_html = ""
    if !isempty(page_foot_path) && isfile(page_foot_path)
        page_foot_html = html2(read(page_foot_path, String), ctx)
    end

    # add the content tags if required
    c_tag   = getvar(ctx, :content_tag)::String
    c_class = getvar(ctx, :content_class)::String
    c_id    = getvar(ctx, :content_id)::String

    # Assemble the body, wrap it in tags if required
    page_content_html = html(page_content_md, ctx)

    body_html = ""
    if !isempty(c_tag)
        body_html = """
            <$(c_tag) $(attr(:class, c_class)) $(attr(:id, c_id))>
              $page_content_html
              $page_foot_html
            </$(c_tag)>
            """
    else
        body_html = """
            $page_content_html
            $page_foot_html
            """
    end

    # Assemble the full page
    full_page_html = ""
    # > head if it exists
    head_path = path(:folder) / getgvar(:layout_head)::String
    if !isempty(head_path) && isfile(head_path)
        full_page_html = html2(read(head_path, String), ctx)
    end

    # > attach the body
    full_page_html *= body_html
    # > then the foot if it exists
    foot_path = path(:folder) / getgvar(:layout_foot)::String
    if !isempty(foot_path) && isfile(foot_path)
        full_page_html *= html2(read(foot_path, String), ctx)
    end

    return full_page_html
end

"""
    _process_md_file_latex
"""
function _process_md_file_latex(ctx::LocalContext, page_content_md::String)
    page_content_latex = latex(page_content_md, ctx)

    full_page_latex = raw"\begin{document}" * "\n\n"
    head_path = path(:folder) / getgvar(:layout_head_lx)::String
    if !isempty(head_path) && isfile(head_path)
        full_page_latex = read(head_path, String)
    end
    full_page_latex *= page_content_latex
    full_page_latex *= "\n\n" * raw"\end{document}"

    return full_page_latex
end
