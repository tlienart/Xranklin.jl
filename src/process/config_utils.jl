#
# Process files for the global environment
#
# --> config.md file (process_config)
# --> utils.jl  file (process_utils)
#

# -------------- #
# PROCESS CONFIG #
# -------------- #

"""
    process_config(config, gc)

Process a configuration string into a given global context object. The
configuration can be given explicitly as a string to allow for
pre-configuration (e.g. a Utils package generating a default config).
"""
function process_config(
            gc::GlobalContext,
            config::String
        )::Nothing

    crumbs(@fname)

    # ensure we're in the relevant gc
    set_current_global_context(gc)
    # set the notebook counters at the top
    reset_counter!(gc.nb_code)
    reset_counter!(gc.nb_vars)

    # Effective config processing: run html as usual for a .md file except that
    # we ignore the resulting HTML; we just use that to populate fields such as
    # lxdefs etc
    start = time(); @info """
        ⌛ processing config.md
        """    
    html(config, gc)
    δt = time() - start; @info """
        ... [config.md] ✔ $(hl(time_fmt(δt)))
        """

    _config_checks(gc)
    return
end

function process_config(gc::GlobalContext)
    config_path = path(:folder) / "config.md"
    if isfile(config_path)
        process_config(gc, read(config_path, String))
    else
        @warn """
            Process config
            Config file $config_path not found.
            """
    end
    return
end


"""
    _config_checks(gc)

Apply some basic chekcs to what might have been set as value for variables in
config file. This may expand over time to help config settings.
"""
function _config_checks(
            gc::GlobalContext
        )::Nothing

    #
    # 1. if website_url is given, check it matches the format, otherwise try
    #    to continue with an implicit format
    #
    website_url = getvar(gc, :website_url, "")
    if !isempty(website_url)
        if endswith(website_url, "index.html")
            website_url =  website_url[1:end-10]
        elseif !endswith(website_url, '/')
            website_url *= '/'
        end
        setvar!(gc, :website_url, website_url)
    end

    #
    # 2. if generate_rss, check that the template files exist
    #
    generate_rss = getvar(gc, :generate_rss, false)
    if generate_rss
        rss_file = noext(getvar(gc, :rss_file, "feed"))
        rss_url  = website_url * rss_file * ".xml"
        setvar!(gc, :rss_feed_url, rss_url)

        # check that template files are there
        rss_head = path(gc, :rss) / getvar(gc, :rss_layout_head, "")
        rss_item = path(gc, :rss) / getvar(gc, :rss_layout_item, "")
        if !isfile(rss_head) || !isfile(rss_item)
            @warn """
                Process config.md
                When `generate_rss=true`, `rss_layout_head` & `rss_layout_item`
                must point to existing files.
                Setting `generate_rss=false` in the meantime.
                """
            setvar!(gc, :generate_rss, false)
        end
    end

    #
    # 3. if generate_sitemap, set the sitemap_url
    #
    generate_sitemap = getvar(gc, :generate_sitemap, false)
    if generate_sitemap
        sitemap_file = noext(getvar(gc, :sitemap_file, "sitemap"))
        sitemap_url  = website_url * sitemap_file * ".xml"
        setvar!(gc, :_sitemap_url, sitemap_url)
    end
    return
end


# ------------- #
# PROCESS UTILS #
# ------------- #

"""
    process_utils(utils, gc)

Process a utils string into a given global context object.
"""
function process_utils(
            gc::GlobalContext,
            utils::String
        )::Nothing

    crumbs(@fname)

    # ensure we're in the relevant gc
    set_current_global_context(gc)
    # set the notebooks at the top
    reset_counter!(gc.nb_code)
    reset_counter!(gc.nb_vars)
    # keep track of utils code
    setvar!(gc, :_utils_code, utils)
    # update the gc modules to use the utils
    # we disable warnings here as docstrings update might
    # show warnings and we don't care.
    pre_log_level = Base.CoreLogging._min_enabled_level[]
    Logging.disable_logging(Logging.Warn)
    for m in (gc.nb_vars.mdl, gc.nb_code.mdl)
        include_string(
            m.Utils,
            utils_code(gc, m, crop=true)
        )
    end
    Base.CoreLogging._min_enabled_level[] = pre_log_level

    # check names of hfun, lx and vars; since we wiped the module before the
    # include_string, all the proper names recuperated here are 'fresh'.
    mdl = utils_module(gc)
    ns  = String.(names(mdl, all=true))

    filter!(
        n -> n[1] != '#' &&
             n ∉ ("eval", "include", string(nameof(mdl))),
        ns
    )
    setvar!(gc, :_utils_hfun_names,
        Symbol.(n[6:end] for n in ns if startswith(n, "hfun_")))
    setvar!(gc, :_utils_lxfun_names,
        Symbol.(n[4:end] for n in ns if startswith(n, "lx_")))
    setvar!(gc, :_utils_envfun_names,
        Symbol.(n[5:end] for n in ns if startswith(n, "env_")))
    setvar!(gc, :_utils_var_names,
        Symbol.(n for n in ns if
            !(startswith(n, r"lx_|hfun_|env_") | (n ∈ UTILS_UTILS))))
    return
end

function process_utils(gc::GlobalContext)
    utils_path = path(:folder) / "utils.jl"
    if isfile(utils_path)
        process_utils(gc, read(utils_path, String))
    else
        @info "❎ no utils file found."
    end
    return
end


utils_hfun_names(gc)   = getvar(gc, :_utils_hfun_names, Vector{Symbol}())
utils_lxfun_names(gc)  = getvar(gc, :_utils_lxfun_names, Vector{Symbol}())
utils_envfun_names(gc) = getvar(gc, :_utils_envfun_names, Vector{Symbol}())
utils_var_names(gc)    = getvar(gc, :_utils_var_names, Vector{Symbol}())
