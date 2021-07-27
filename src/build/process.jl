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

    start = time(); @info """
        ⌛ processing config
        """
    html(config, gc)
    @info """
        ... ✔ $(hl(time_fmt(time()-start)))
        """
    if value(gc, :generate_rss)::Bool
        # :website_url must be given
        url = value(gc, :rss_website_url)::String
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
            full_url =  url * value(gc, :rss_file)::String * ".xml"
            setvar!(gc, :rss_feed_url, full_url)
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
    process_file(a...; kw...)

Take a file (markdown, html, ...) and process it appropriately:

* copy it "as is" in `__site`
* generate a derived file into `__site`
"""
function process_file(
            fpair::Pair{String,String},
            case::Symbol,
            t::Float64=0.0;     # compare modif time
            gc::GlobalContext=cur_gc()
            )

    # there's things we don't want to copy over or (re)process
    fpath = joinpath(fpair...)
    skip = startswith(fpath, path(:layout)) ||
           startswith(fpath, path(:literate)) ||
           startswith(fpath, path(:rss)) ||
           fpair.second in ("config.md", "utils.jl")
    skip && return

    opath = form_output_path(fpair, case)

    if case in (:md, :html)
        start = time(); @info """
            ⌛ processing $(hl(get_rpath(fpath), :cyan))
            """
        if case == :md
            process_md_file(gc, fpath, opath)
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
            opath::String
            )
    # path of the file relative to path(:folder)
    rpath  = get_rpath(fpath)
    ropath = get_ropath(opath)
    ctx    = DefaultLocalContext(gc, id=rpath)

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
    page_foot_path = path(:folder) / valueglob(:layout_page_foot)::String
    page_foot_html = ""
    if !isempty(page_foot_path) && isfile(page_foot_path)
        page_foot_html = read(page_foot_path, String)
    end

    # add the content tags if required
    c_tag   = value(ctx, :content_tag)::String
    c_class = value(ctx, :content_class)::String
    c_id    = value(ctx, :content_id)::String

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
    head_path = path(:folder) / valueglob(:layout_head)::String
    if !isempty(head_path) && isfile(head_path)
        full_page_html = read(head_path, String)
    end

    # attach the body
    full_page_html *= body_html

    # then the foot if it exists
    foot_path = path(:folder) / valueglob(:layout_foot)::String
    if !isempty(foot_path) && isfile(foot_path)
        full_page_html *= read(foot_path, String)
    end

    # write to file
    write(opath, full_page_html)
    return
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
