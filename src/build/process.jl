"""
    process_config(config, gc)

Process a configuration string into a given global context object. The
configuration can be given explicitly as a string to allow for
pre-configuration (e.g. a Utils package generating a default config).
"""
function process_config(
            config::String,
            gc::GlobalContext=cur_gc();
            initial_pass::Bool=false
            )
    crumbs("process_config")

    # ensure we're in the relevant gc
    set_current_global_context(gc)
    # set the notebook counters at the top
    reset_notebook_counters!(gc)

    # try to load from cache if relevant
    if initial_pass
        fpv = path(:cache) / "gnbv.json"
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

function process_config(gc::GlobalContext=cur_gc(); initial_pass::Bool=false)
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


"""
    process_utils(utils, gc)

Process a utils string into a given global context object.
"""
function process_utils(
            utils::String,
            gc::GlobalContext=cur_gc();
            initial_pass::Bool=false
            )
    crumbs("process_utils")

    # ensure we're in the relevant gc
    set_current_global_context(gc)
    # set the notebooks at the top
    reset_notebook_counters!(gc)

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

function process_utils(gc::GlobalContext=cur_gc(); initial_pass::Bool=false)
    utils_path = path(:folder) / "utils.jl"
    if isfile(utils_path)
        process_utils(read(utils_path, String), gc; initial_pass)
    else
        @info "❎ no utils file found."
    end
    return
end

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

* process_file -> process_md_file   -> process_md_file_io!
* process_file -> process_html_file -> process_html_file_io!
"""
function process_file(
            fpair::Pair{String,String},
            case::Symbol,
            t::Float64=0.0;             # compare modif time
            gc::GlobalContext=cur_gc(),
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
            initial_pass || process_triggers(gc, skip_files)

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
            tohtml::Bool=true
            )::Nothing
    crumbs("process_md_file_io!", fpath)

    # usually not necessary apart if triggered from getvarfrom
    isfile(fpath) || return
    # path of the file relative to path(:folder)
    rpath  = get_rpath(fpath)
    ropath = get_ropath(opath)

    # if it's the initial pass and the gc already has a reference to this
    # file, it means it's already been processed (e.g. cached or because
    # it was triggered by another page requesting a var from it)
    in_gc = rpath in keys(gc.children_contexts)
    if initial_pass && in_gc
        @debug "🚀 skipping (page already processed)."
        return
    end

    # CONTEXT
    # -------
    # retrieve the context from gc's children if it exists or
    # create it if it doesn't
    ctx = in_gc ?
            gc.children_contexts[rpath] :
            DefaultLocalContext(gc; rpath)
    # set it as current context in case it isn't
    set_current_local_context(ctx)
    # reset the headers
    empty!(ctx.headers)
    # reset code counter
    setvar!(ctx, :_auto_cell_counter, 1)

    if initial_pass
        # try to load notebooks from serialized
        fpv = path(:cache) / noext(rpath) / "nbv.json"
        fpc = path(:cache) / noext(rpath) / "nbc.json"
        isfile(fpv) && load_vars_cache!(ctx, fpv)
        isfile(fpc) && load_code_cache!(ctx, fpc)
    else
        # reset the notebook counters at the top
        reset_notebook_counters!(ctx)
    end

    # set meta parameters
    s = stat(fpath)
    setvar!(ctx, :_relative_path, rpath)
    setvar!(ctx, :_relative_url, unixify(ropath))
    setvar!(ctx, :_creation_time, s.ctime)
    setvar!(ctx, :_modification_time, s.mtime)

    # get and convert markdown
    page_content_md = read(fpath, String)
    output = (tohtml ?
                _process_md_file_html(ctx, page_content_md) :
                _process_md_file_latex(ctx, page_content_md))::String

    write(io, output)
    return
end

function process_md_file(
            gc::GlobalContext,
            fpath::String,
            opath::String;
            kw...)
    open(opath, "w") do outf
        process_md_file_io!(outf, gc, fpath; opath, kw...)
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

function _process_md_file_html(ctx::Context, page_content_md::String)
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

function _process_md_file_latex(ctx::Context, page_content_md::String)
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
    process_triggers(gc)

See if earlier processing incurred any dependent processing by having modified
some page variables. The typical case is when definitions change in the config
file and all pages that use those definitions should be re-processed.
"""
function process_triggers(gc::GlobalContext, skip_files::Vector{Pair{String, String}})
    crumbs("process_triggers")

    # see if it incurred re-triggers
    re_process = gc.to_trigger
    empty!(gc.to_trigger)
    for c in values(gc.children_contexts)
        union!(re_process, c.to_trigger)
        empty!(c.to_trigger)
    end

    for rpath in re_process
        start = time(); @info """
            ⌛ re-proc $(hl(str_fmt(rpath), :cyan)) (depends on updated vars)
            """
        fpair = path(:folder) => rpath
        process_file(
            path(:folder) => rpath,
            ifelse(splitext(rpath)[2] == ".html", :html, :md);
            gc, skip_files, initial_pass=false
        )
        δt = time() - start; @info """
            ... ✔ [reproc] $(hl(time_fmt(δt)))
            """
    end
end
