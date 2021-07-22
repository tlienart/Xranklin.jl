"""
    process_config(gc, config)

Process a configuration file into a given global context object.
The configuration can be given explicitly as a string to allow
for pre-configuration (e.g. a Utils package generating a default
config).
"""
function process_config(
            config::String,
            gc::GlobalContext=env(:cur_global_ctx)
            )

    html(config, gc)
    if value(gc, :generate_rss, false)
        # :website_url must be given
        url = value(gc, :rss_website_url, "")
        if isempty(url)
            @warn """
                When `generate_rss=true`, `rss_website_url` must be given.
                Setting `generate_rss=false` in the meantime.
                """
            setvar!(gc, :generate_rss, false)
        else
            endswith(url, '/') || (url *= '/')
            full_url =  url * value(gc, :rss_file, "feed") * ".xml"
            setvar!(gc, :rss_feed_url, full_url)
        end
    end
    return
end

function process_config(gc::GlobalContext=env(:cur_global_ctx))
    config_path = path(:folder) / "config.md"
    if isfile(config_path)
        process_config(read(config_path, String), gc)
    else
        @warn "Config file $config not found."
    end
end


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
            gc::GlobalContext=env(:cur_global_ctx)
            )

    # there's things we don't want to copy over or (re)process
    fpath = joinpath(fpair...)
    skip = startswith(fpath, path(:layout)) ||
           startswith(fpath, path(:literate)) ||
           startswith(fpath, path(:rss)) ||
           fpair.second in ("config.md", "utils.jl")
    skip && return

    opath = form_output_path(fpair, case)

    if case == :md
        start = time(); @info """
            ⌛ processing $fpair...
            """
        process_md_file(gc, fpath, opath)
        @info """
            ... ✔ $(time_fmt(time()-start))
            """
    elseif case == :html
        start = time(); @info """
            ⌛ processing $fpair...
            """
        process_html_file(gc, fpath, opath)
        @info """
            ... ✔ $(time_fmt(time()-start))
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


function process_md_file(
            gc::GlobalContext,
            fpath::String,
            opath::String
            )
    # path of the file relative to path(:folder)
    rpath  = get_rpath(fpath)
    ropath = get_ropath(opath)
    ctx    = DefaultLocalContext(gc, id=rpath)

    start = time()
    @info """
        ⌛ processing file $rpath
        """

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
    page_foot_path = path(:folder) / valueglob(:layout_page_foot, "")
    page_foot_html = ""
    if !isempty(page_foot_path) && isfile(page_foot_path)
        page_foot_html = read(page_foot_path, String)
    end

    # add the content tags if required
    c_tag   = value(ctx, :content_tag, "div")
    c_class = value(ctx, :content_class, "franklin-content")
    c_id    = value(ctx, :content_id, "")

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

    full_page_html = ""
    head_path = path(:folder) / valueglob(:layout_head, "")
    if !isempty(head_path) && isfile(head_path)
        full_page_html = read(head_path, String)
    end

    full_page_html *= body_html

    foot_path = path(:folder) / valueglob(:layout_foot, "")
    if !isempty(foot_path) && isfile(foot_path)
        full_page_html *= read(foot_path, String)
    end

    write(opath, full_page_html)
    @info """
        ... ✔ $(time_fmt(time()-start)), wrote: $opath
        """
    return
end
