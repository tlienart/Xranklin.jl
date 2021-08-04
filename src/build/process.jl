"""
    process_config(config, gc)

Process a configuration string into a given global context object. The
configuration can be given explicitly as a string to allow for
pre-configuration (e.g. a Utils package generating a default config).
"""
function process_config(
            config::String,
            gc::GlobalContext=cur_gc()
            )
    # set the notebooks at the top
    reset_notebook_counters!(gc)
    set_current_global_context(gc)

    old_lxdefs = LittleDict{String, UInt64}(
        n => hash(lxd.def)
        for (n, lxd) in gc.lxdefs
    )
    # discard current defs, it will be repopulated by the call to html
    empty!(gc.lxdefs)

    start = time(); @info """
        ⌛ processing config
        """
    html(config, gc)
    δt = time() - start; @info """
        ... [config] ✔ $(hl(time_fmt(δt)))
        """

    if getvar(gc, :generate_rss)::Bool
        # :website_url must be given
        url = getvar(gc, :rss_website_url)::String
        if isempty(url)
            @warn """
                Process config
                --------------
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
        n
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

function process_config(gc::GlobalContext=cur_gc())
    config_path = path(:folder) / "config.md"
    if isfile(config_path)
        process_config(read(config_path, String), gc)
    else
        @warn """
            Process config
            --------------
            Config file $config not found.
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
            gc::GlobalContext=cur_gc()
            )
    # set the notebooks at the top
    reset_notebook_counters!(gc)
    set_current_global_context(gc)

    start = time(); @info """
        ⌛ processing utils
        """
    eval_code_cell!(gc, subs(utils); cell_name="utils")
    @info """
        ... [utils] ✔ $(hl(time_fmt(time()-start)))
        """

    # check names of hfun, lx and vars; since we wiped the module before the
    # include_string, all the proper names recuperated here are 'fresh'.
    mdl = gc.nb_code.mdl
    ns = String.(names(mdl, all=true))
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

function process_utils(gc::GlobalContext=cur_gc())
    utils_path = path(:folder) / "utils.jl"
    if isfile(utils_path)
        process_utils(read(utils_path, String), gc)
    else
        @info "❎ no utils file found."
    end
    return
end

utils_hfun_names()  = getgvar(:_utils_hfun_names)::Vector{Symbol}
utils_lxfun_names() = getgvar(:_utils_lxfun_names)::Vector{Symbol}
utils_var_names()   = getgvar(:_utils_var_names)::Vector{Symbol}



"""
    process_file(a...; kw...)

Take a file (markdown, html, ...) and process it appropriately:

* copy it "as is" in `__site`
* generate a derived file into `__site`
"""
function process_file(
            fpair::Pair{String,String},
            case::Symbol,
            t::Float64=0.0;     # compare modif time
            gc::GlobalContext=cur_gc(),
            skip_files::Vector{Pair{String, String}}=Pair{String, String}[],
            initial_pass::Bool=false
            )

    # there's things we don't want to copy over or (re)process
    fpath = joinpath(fpair...)
    skip = startswith(fpath, path(:layout)) ||
           startswith(fpath, path(:literate)) ||
           startswith(fpath, path(:rss)) ||
           fpair.second in ("config.md", "utils.jl") ||
           fpair in skip_files
    skip && return

    opath = form_output_path(fpair, case)

    if case in (:md, :html)
        start = time(); @info """
            ⌛ processing $(hl(get_rpath(fpath), :cyan))
            """
        if case == :md
            process_md_file(gc, fpath, opath; initial_pass=initial_pass)
        elseif case == :html
            process_html_file(gc, fpath, opath)
        end
        ropath = "__site"/get_ropath(opath)
        @info """
            ... ✔ $(hl(time_fmt(time()-start))), wrote $(hl((str_fmt(ropath)), :cyan))
            """
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
    process_md_file(gc, fpath, opath)

Process a markdown file located at `fpath` within global context `gc` and
write the result at `opath`.
"""
function process_md_file(
            gc::GlobalContext,
            fpath::String,
            opath::String;
            initial_pass::Bool = false
            )::Nothing
    # usually not necessary apart in getvarfrom
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

    # retrieve the context from gc's children if it exists or
    # create it if it doesn't
    ctx = in_gc ?
            gc.children_contexts[rpath] :
            DefaultLocalContext(gc, rpath=rpath)

    # reset the notebooks at the top
    reset_notebook_counters!(ctx)
    set_current_local_context(ctx)

    # set meta parameters
    s = stat(fpath)
    setvar!(ctx, :_relative_path, rpath)
    setvar!(ctx, :_relative_url, unixify(ropath))
    setvar!(ctx, :_creation_time, s.ctime)
    setvar!(ctx, :_modification_time, s.mtime)

    # get and convert markdown for the core
    page_content_md   = read(fpath, String)
    page_content_html = html(page_content_md, ctx)

    # get and process html for the foot of the page
    page_foot_path = path(:folder) / getgvar(:layout_page_foot)::String
    page_foot_html = ""
    if !isempty(page_foot_path) && isfile(page_foot_path)
        page_foot_html = read(page_foot_path, String)
    end

    # add the content tags if required
    c_tag   = getvar(ctx, :content_tag)::String
    c_class = getvar(ctx, :content_class)::String
    c_id    = getvar(ctx, :content_id)::String

    # Assemble the body, wrap it in tags if required
    body_html = ""
    if !isempty(c_tag)
        body_html = """
            <$(c_tag)$(html_attr(:class, c_class))$(html_attr(:id, c_id))>
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

    # head if it exists
    head_path = path(:folder) / getgvar(:layout_head)::String
    if !isempty(head_path) && isfile(head_path)
        full_page_html = read(head_path, String)
    end

    # attach the body
    full_page_html *= body_html

    # then the foot if it exists
    foot_path = path(:folder) / getgvar(:layout_foot)::String
    if !isempty(foot_path) && isfile(foot_path)
        full_page_html *= read(foot_path, String)
    end

    # write to file
    write(opath, full_page_html)
    return
end

function process_md_file(gc::GlobalContext, rpath::String; kw...)
    fpath = path(:folder)/rpath
    d, f = splitdir(fpath)
    opath = form_output_path(d => f, :md)
    process_md_file(gc, fpath, opath; kw...)
end


"""
    process_html_file(gc, fpath, opath)

Process a html file located at `fpath` within global context `gc` and
write the result at `opath`.
"""
function process_html_file(
            gc::GlobalContext,
            fpath::String,
            opath::String
            )
    throw(ErrorException("Not Implemented Yet"))
end
