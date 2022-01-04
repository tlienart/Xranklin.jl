"""
    process_config(config, gc)

Process a configuration string into a given global context object. The
configuration can be given explicitly as a string to allow for
pre-configuration (e.g. a Utils package generating a default config).
"""
function process_config(
            config::String,
            gc::GlobalContext;
            initial_pass::Bool=false
            )
    crumbs("process_config")

    # ensure we're in the relevant gc
    set_current_global_context(gc)
    # set the notebook counters at the top
    reset_notebook_counters!(gc)

    # try to load from cache if relevant
    if initial_pass
        fpv = path(:cache) / "gnbv.cache"
        isfile(fpv) && load_vars_cache!(gc, fpv)
    end

    # keep track of current lxdefs to see if the config.md redefines
    # them; if that's the case (either changed or removed) update all
    # pages dependent on these defs later.
    old_lxdefs = LittleDict{String, UInt64}(
        n => hash(lxd.def)
        for (n, lxd) in gc.lxdefs
    )
    # discard current defs, it will be repopulated by the call to html
    empty!(gc.lxdefs)

    # -----------------------
    start = time(); @info """
        ⌛ processing config
        """
    # -----------------------

    html(config, gc)

    # ------------------------------------
    δt = time() - start; @info """
        ... [config] ✔ $(hl(time_fmt(δt)))
        """
    # ------------------------------------

    if getvar(gc, :generate_rss)::Bool
        # :website_url must be given
        url = getvar(gc, :rss_website_url)::String
        if isempty(url)
            @warn """
                Process config
                When `generate_rss=true`, `rss_website_url` must be given.
                Setting `generate_rss=false` in the meantime.
                """
            setvar!(gc, :generate_rss, false)
        else
            endswith(url, '/') || (url *= '/')
            full_url =  url * getvar(gc, :rss_file)::String * ".xml"
            setvar!(gc, :rss_feed_url, full_url)
        end
    end

    # go over the old lxdefs and check the ones that either have been
    # removed or updated
    updated_lxdefs = [
        (@debug "✋ lxdef $n has changed"; n)
        for (n, h) in old_lxdefs

        if n ∉ keys(gc.lxdefs) || h != hash(gc.lxdefs[n].def)
    ]

    # if there are updated lxdefs, find the pages which this might affect
    # and mark them for re-processing
    if !isempty(updated_lxdefs)
        for (rpath, ctx) in gc.children_contexts
            if anymatch(ctx.req_lxdefs["__global"], updated_lxdefs)
                union!(gc.to_trigger, [rpath])
            end
        end
    end
    return
end

function process_config(gc::GlobalContext; initial_pass::Bool=false)
    config_path = path(:folder) / "config.md"
    if isfile(config_path)
        process_config(read(config_path, String), gc; initial_pass)
    else
        @warn """
            Process config
            Config file $config_path not found.
            """
    end
    return
end

process_config(config::String) = process_config(config, cur_gc())
process_config() = process_config(cur_gc())


"""
    process_utils(utils, gc)

Process a utils string into a given global context object.
"""
function process_utils(
            utils::String,
            gc::GlobalContext
            )
    crumbs("process_utils")

    # ensure we're in the relevant gc
    set_current_global_context(gc)
    # set the notebooks at the top
    reset_notebook_counters!(gc)
    # keep track of utils (see `using_utils!`)
    setvar!(gc, :_utils_code, utils)

    # -----------------------
    start = time(); @info """
        ⌛ processing utils
        """
    # -----------------------

    eval_code_cell!(gc, subs(utils); cell_name="utils")

    # ---------------------------------------------
    @info """
        ... [utils] ✔ $(hl(time_fmt(time()-start)))
        """
    # ---------------------------------------------

    # check names of hfun, lx and vars; since we wiped the module before the
    # include_string, all the proper names recuperated here are 'fresh'.
    mdl = gc.nb_code.mdl
    ns  = String.(names(mdl, all=true))
    filter!(
        n -> n[1] != '#' &&
             n ∉ ("eval", "include", string(nameof(mdl))),
        ns
    )
    setvar!(gc, :_utils_hfun_names,
                Symbol.([n[6:end] for n in ns if startswith(n, "hfun_")]))
    setvar!(gc, :_utils_lxfun_names,
                Symbol.([n[4:end] for n in ns if startswith(n, "lx_")]))
    setvar!(gc, :_utils_var_names,
                Symbol.([n for n in ns if !startswith(n, r"lx_|hfun_")]))
    return
end

function process_utils(gc::GlobalContext)
    utils_path = path(:folder) / "utils.jl"
    if isfile(utils_path)
        process_utils(read(utils_path, String), gc)
    else
        @info "❎ no utils file found."
    end
    return
end

process_utils(utils::String) = process_utils(utils, cur_gc())
process_utils() = process_utils(cur_gc())


utils_hfun_names()   = getgvar(:_utils_hfun_names)::Vector{Symbol}
utils_lxfun_names()  = getgvar(:_utils_lxfun_names)::Vector{Symbol}
utils_envfun_names() = getgvar(:_utils_envfun_names)::Vector{Symbol}
utils_var_names()    = getgvar(:_utils_var_names)::Vector{Symbol}



"""
    process_file(a...; kw...)

Take a file (markdown, html, ...) and process it appropriately:

* copy it "as is" in `__site`
* generate a derived file into `__site`

## Paths

* process_file -> process_md_file   -> process_md_file_io!    (writes to file)
* process_file -> process_html_file -> process_html_file_io!  (writes to file)
"""
function process_file(
            gc::GlobalContext,
            fpair::Pair{String,String},
            case::Symbol,
            t::Float64=0.0;             # compare modif time
            skip_files::Vector{Pair{String, String}}=Pair{String, String}[],
            initial_pass::Bool=false
            )
    crumbs("process_file", "$(fpair.first) => $(fpair.second)")

    # there's things we don't want to copy over or (re)process
    fpath = joinpath(fpair...)
    skip  = startswith(fpath, path(:layout))    ||  # no copy
            startswith(fpath, path(:literate))  ||  # no copy
            startswith(fpath, path(:rss))       ||  # no copy
            fpair in skip_files                     # skip
    skip && return

    opath = form_output_path(fpair, case)
    if case in (:md, :html)
        # ----------------------------------------------
        start = time(); @info """
            ⌛ processing $(hl(str_fmt(get_rpath(fpath)), :cyan))
            """
        # ----------------------------------------------

        if case == :md
            process_md_file(gc, fpath, opath; initial_pass=initial_pass)
            if !initial_pass
                # reprocess all pages that depend upon definitions from this page
                rpath = get_rpath(fpath)
                for r in gc.children_contexts[rpath].to_trigger
                    reprocess(r, gc; skip_files, msg="(depends on updated vars)")
                end
            end

        elseif case == :html
            process_html_file(gc, fpath, opath)

        end
        ropath = "__site"/get_ropath(opath)

        # ----------------------------------------------------------------------------
        @info """
            ... [process] ✔ $(hl(time_fmt(time()-start))), wrote $(hl(str_fmt(ropath), :cyan))
            """
        # ----------------------------------------------------------------------------

    else
        # copy the file over if
        # - it's not already there
        # - it's there but we have a more recent version that's not identical
        if !isfile(opath) || (mtime(opath) < t && !filecmp(fpath, opath))
            cp(fpath, opath, force=true)
        end
    end
    return
end

process_file(fpair::Pair{String,String}, case::Symbol, t::Float64=0.0; kw...) =
    process_file(cur_gc(), fpair, case, t; kw...)


"""
    process_md_file_io!(io, gc, fpath, opath)

Process a markdown file located at `fpath` within global context `gc` and
write the result to the iostream `io`.
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

    # set it as current context in case it isn't
    set_current_local_context(lc)
    # reset the headers
    empty!(lc.headers)
    # reset the eqs counter
    eqrefs(lc)["__cntr__"] = 0
    # reset code counter
    setvar!(lc, :_auto_cell_counter, 0)
    # keep track of the anchors pre-processing to see which ones
    # are removed (see context/anchors)
    bk_anchors = copy(lc.anchors)
    empty!(lc.anchors)

    initial_cache_used = false
    if initial_pass
        # try to load notebooks from serialized
        fpv = path(:cache) / noext(rpath) / "nbv.cache"
        fpc = path(:cache) / noext(rpath) / "nbc.cache"

        if isfile(fpv)
            load_vars_cache!(lc, fpv)
            initial_cache_used = true
        end
        if isfile(fpc)
            load_code_cache!(lc, fpc)
            initial_cache_used = true
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

    # get and convert markdown
    page_content_md = read(fpath, String)
    output = (tohtml ?
                _process_md_file_html(lc, page_content_md) :
                _process_md_file_latex(lc, page_content_md))::String

    # only here do we know whether `ignore_cache` was set to 'true'
    # if that's the case, reset the code notebook and re-evaluate.
    if initial_cache_used && getvar(lc, :ignore_cache, false)
        reset_code_notebook!(lc)
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

function process_md_file(
            gc::GlobalContext,
            fpath::String,
            opath::String;
            initial_pass::Bool=false,
            kw...)::Nothing

    # check if the file should be skipped
    # 1> usually not necessary apart if triggered from getvarfrom
    isfile(fpath) || return
    # 2> check if the file has already been processed and in initial pass
    # (this may happen in the case of getvarfrom)
    rpath = get_rpath(fpath)
    in_gc = rpath in keys(gc.children_contexts)
    if initial_pass && in_gc
        @debug "🚀 skipping $rpath (page already processed)."
        return
    end

    # otherwise process the page and write to opath
    open(opath, "w") do outf
        process_md_file_io!(outf, gc, fpath; opath, initial_pass, in_gc, kw...)
    end
    return
end

function process_md_file(gc::GlobalContext, rpath::String; kw...)
    crumbs("process_md_file", rpath)
    fpath = path(:folder) / rpath
    d, f  = splitdir(fpath)
    opath = form_output_path(d => f, :md)
    process_md_file(gc, fpath, opath; kw...)
end

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


"""
    process_html_file(ctx, fpath, opath)

Process a html file located at `fpath` within context `ctx` and write
the result at `opath`.
Note: in general the context is a global one apart from when it's
triggered from an insert in which case it will be the current active
context (see `cur_ctx`).
"""
function process_html_file(
            ctx::Context,
            fpath::String,
            opath::String
            )
    crumbs("process_html_file", fpath)

    open(opath, "w") do io
        process_html_file_io!(io, ctx, fpath)
    end
    return
end

"""
    process_html_file_io!(io, ctx, fpath)

Process a html file located at `fpath` within context `ctx` and write
the result to the io stream `io`.

See note for process_html_file about current context.
"""
function process_html_file_io!(
            io::Union{IOStream, IOBuffer},
            ctx::Context,
            fpath::String
            )
    # ensure we're in the relevant context
    if isglob(ctx)
        set_current_global_context(gc)
    else
        set_current_local_context(ctx)
    end

    # get html, postprocess it & write it
    write(io, html2(read(fpath, String), ctx))
    return
end


"""
    reprocess(rpath, gc; skip_files, msg)

Re-process a md file at 'rpath' as it may depend on things that will only be
available at the time of the re-processing.
"""
function reprocess(
            rpath::String, gc::GlobalContext;
            skip_files::Vector{Pair{String, String}}=Pair{String,String}[],
            msg::String=""
            )::Nothing
    # check if the file was marked as to be skipped
    fpair = path(:folder) => rpath
    fpair in skip_files && return
    # otherwise reprocess the file
    case = ifelse(splitext(rpath)[2] == ".html", :html, :md)
    start = time(); @info """
        ⌛ re-proc $(hl(str_fmt(rpath), :cyan)) $msg
        """
    process_file(gc, fpair, case)
    δt = time() - start; @info """
        ... ✔ [reproc] $(hl(time_fmt(δt)))
        """
    return
end
