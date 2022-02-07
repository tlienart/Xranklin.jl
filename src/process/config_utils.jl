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
        fpdm = path(:cache) / "gdm.cache"
        fpv  = path(:cache) / "gnbv.cache"
        isfile(fpdm) && merge!(gc.deps_map, deserialize(fpdm))
        isfile(fpv)  && load_vars_cache!(gc, fpv)
    end

    # keep track of current lxdefs to see if the config.md redefines
    # them; if that's the case (either changed or removed) update all
    # pages dependent on these defs at the end of this function.
    old_lxdefs = LittleDict{String, UInt64}(
        n => hash(lxd.def)
        for (n, lxd) in gc.lxdefs
    )
    # discard current defs, it will be repopulated by the call to html
    empty!(gc.lxdefs)

    # -------------------------------------------
    start = time(); @info """
        ⌛ processing config.md
        """

    html(config, gc)

    δt = time() - start; @info """
        ... [config.md] ✔ $(hl(time_fmt(δt)))
        """
    # -------------------------------------------

    if getvar(gc, :generate_rss)::Bool
        # :website_url must be given
        url = getvar(gc, :rss_website_url)::String
        if isempty(url)
            @warn """
                Process config.md
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

process_config(config::String; kw...) = process_config(config, cur_gc(); kw...)
process_config(; kw...) = process_config(cur_gc(); kw...)


# ------------- #
# PROCESS UTILS #
# ------------- #

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

    # -----------------------------------------------------
    start = time(); @info """
        ⌛ processing utils.jl
        """

    eval_code_cell!(gc, strip(utils), "utils")

    @info """
        ... [utils.jl] ✔ $(hl(time_fmt(time()-start)))
        """
    # -----------------------------------------------------

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
