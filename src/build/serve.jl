"""
    serve(d; kw...)

Runs Franklin in the directory `d` (current directory if unspecified).

## Keyword Arguments

    folder (String)     : website folder, this is the folder which is expected
                           to contain the config.md as well as the
                           index.(md|html).
    dir (String)        : same as `folder`.
    clear (Bool)        : whether to clear everything and start from scratch,
                           this will clear the `__*` directories.
                           This can be used when something got corrupted e.g.
                           by having inadvertently modified files in one of
                           those folders or if somehow a lot of stale files
                           accumulated in one of these folders.
    final (Bool)        : whether it's the build (e.g. for CI or publication),
                           in this case all links are adjusted to reflect the
                           'prepath'.
    single (Bool)       : do a single build pass and stop.
    eval (Bool)         : if set to false, ignore all code evaluations.
    nocode (Bool)       : opposite of eval.
    use_threads (Bool)  : [EXPERIMENTAL] if set to true, use multi-threading
                           in the full pass. You can only use this if there
                           is a single, site-wide environment (single Project
                           and Manifest files). Also, if your pages make use of
                           code (both page variables or actual code), then their
                           processing will lock, effectively defeating the
                           multi-threading. This is because code-execution needs
                           to be captured, this is done with IOCapture which,
                           for now, requires to be locked.
                           https://github.com/JuliaDocs/IOCapture.jl/issues/14

    base_url_prefix (String)  : override the base url prefix and force it to a
                                 given value.
    prepath (String)          : same as `base_url_prefix` (takes precedence).
    prefix (String)           : same as `base_url_prefix`.


### Debugging options

    debug (Bool)    : whether to display debugging messages.
    cleanup (Bool)  : whether to destroy the context objects, when debugging
                       this can be useful to explore local & global variables.
    skip (String[]) : list of rpath to ignore at serve time, this can be useful
                       if one or more page(s) are buggy or long to execute.

### LiveServer arguments

    port (Int)    : port to use for the local server.
    host (String) : host to use for the local server.
    launch (Bool) : whether to launch the browser once the site is built and
                     ready to be viewed. A user who has interrupted a previous
                     `serve` might prefer to set this to `false` as they might
                     have a browser tab pointing to a page of interest.
"""
function serve(
            d::String = "";

            # Main kwargs
            dir::String       = d,
            folder::String    = dir,
            clear::Bool       = false,
            final::Bool       = false,
            single::Bool      = final,
            eval::Bool        = true,
            nocode::Bool      = !eval,
            threads::Bool     = false,
            use_threads::Bool = threads,

            # Base url prefix / prepath optional override
            prepath::String = "",
            prefix::String  = "",
            base_url_prefix::String = ifelse(isempty(prepath),
                                             prefix, prepath),

            # Debugging options
            debug::Bool          = false,
            cleanup::Bool        = true,
            skip::Vector{String} = String[],

            # LiveServer options
            port::Int    = 8000,
            host::String = "127.0.0.1",
            launch::Bool = true,
        )::Nothing

    if debug
        Logging.disable_logging(Logging.Debug - 100)
        ENV["JULIA_DEBUG"] = "all"
    else
        ENV["JULIA_DEBUG"] = ""
    end

    setenv!(:nocode,      nocode)
    setenv!(:use_threads, use_threads & (Threads.nthreads() > 1))

    # Instantiate the global context, this also creates a global vars and code
    # notebooks which each have their module. The first creation of a module
    # will also create the overall `parent_module` in which all modules (for
    # both the global and the local contexts) will live.
    gc     = DefaultGlobalContext()
    folder = ifelse(isempty(folder), pwd(), dir)
    set_paths!(gc, folder)

    # activate the folder environment
    old_project    = Pkg.project().path
    current_folder = path(gc, :folder)
    if isfile(current_folder / "Project.toml")
        Pkg.activate(current_folder)
        Pkg.instantiate()
        setvar!(gc, :project, Pkg.project().path)
    end

    # in case the user explicitly specifies stuff to ignore
    append!(gc.vars[:ignore], skip)

    # if there is a utils.jl that was cached, check if it has changed,
    # if it has, we clear even if clear is false
    cached_utils    = path(gc, :cache)  / "utils.jl"
    current_utils   = path(gc, :folder) / "utils.jl"
    utils_unchanged = !any(isfile, (cached_utils, current_utils)) ||
                      utilscmp(cached_utils, current_utils)

    # same for config except the cached version may be from a .jl or .md
    config_unchanged = false
    for case in ("config.jl", "config.md")
        cached_config    = path(gc, :cache) / case
        current_config   = path(gc, :folder) / case
        config_unchanged = !any(isfile, (cached_config, current_config)) ||
                           filecmp(cached_config, current_config)
        config_unchanged || break
    end

    deserialized_gc = false

    if !clear && isfile(gc_cache_path())
        start = time()
        # try to load previously-serialised contexts if any, the process config
        # and process_utils happen within the deserialise so that children
        # contexts are attached to an up-to-date gc.
        try
            deserialize_gc(gc)
            δt = time() - start; @info """
                🏁 ... done $(hl(time_fmt(δt), :red))
                """
            deserialized_gc = true
        catch
            @info """
                ❌ failed to deserialize cache, maybe the previous session crashed.
                """
            clear = true
        end

        # check if layout files have changed, if they have --> clear
        clear = clear || changed_layout_hashes(gc)
    end

    if clear || !utils_unchanged
        if deserialized_gc
            # changed_layout_hashes -> restart from scratch
            folder = path(gc, :folder)
            gc     = DefaultGlobalContext()
            set_paths!(gc, folder)
        end
        # if clear, destroy output directories if any
        for odir in (path(gc, :site), path(gc, :pdf), path(gc, :cache))
            rm(odir; force=true, recursive=true)
        end

        @debug "clear: $clear / utils: $utils_unchanged; reprocess config/utils"
        process_config(gc)
        process_utils(gc)
    end

    # useful to check if changes to utils are relevant or not, see
    # build_loop and utils_changed
    if isfile(current_utils)
        setvar!(gc, :_utils_code, read(current_utils, String))
    end

    isempty(base_url_prefix) || setvar!(gc, :base_url_prefix, base_url_prefix)

    # scrape the folder to collect all files that should be watched for
    # changes; this set will be updated in the loop if new files get
    # added that should be watched
    wf = find_files_to_watch(gc)

    gc = full_pass(
        gc, wf;
        initial_pass    = true,
        config_changed  = !config_unchanged,
        utils_changed   = !utils_unchanged,
        final,
    )

    # ---------------------------------------------------------------
    # Start the build loop unless we're in single pass mode (single)
    # or in final build mode (final).
    if !any((single, final))
        loop = (cntr, watcher) -> build_loop(cntr, watcher, wf)
        LiveServer.serve(
                port           = port,
                coreloopfun    = loop,
                dir            = path(gc, :site),
                host           = host,
                launch_browser = launch
            )
        println()
    end

    # ---------------------------------------------------------------
    # Finalise by caching notebooks etc
    with_parser_error = String[]
    with_failed_block = String[]
    for (rp, lc) in gc.children_contexts
        if getvar(lc, :_has_parser_error, false)
            push!(with_parser_error, rp)
        elseif getvar(lc, :_has_failed_blocks, false)
            push!(with_failed_block, rp)
        end
    end
    fin   = "."
    noerr = all(isempty, (with_failed_block, with_parser_error))
    if noerr
        fin = " (💯)."
    end
    msg = """
        Processed $(length(gc.children_contexts)) pages$fin
        """
    if !isempty(with_parser_error)
        n = length(with_parser_error)
        msg *= """
            \n⚠ the following page(s) failed to be parsed properly:\n
            """
        for rp in with_parser_error
            msg *= """
                    * $rp
                """
        end
    end
    if !isempty(with_failed_block)
        msg *= """
            \n⚠ the following page(s) have blocks that couldn't be resolved:\n
            """
        for rp in with_failed_block
            msg *= """
                    * $rp
                """
        end
    end
    @info msg * "\n"^(!noerr)
    println()
    @info "Starting caching process & cleanup"

    # cache
    serialize_contexts(gc)

    # ---------------------------------------------------------------
    # Cleanup:
    # > wipe parent module (make all children modules inaccessible
    #   so that the garbage collector should be able to destroy them)
    # > unlink global and local context so that the gc can destroy them.
    if cleanup
        start = time()
        @info "🗑️ cleaning up all objects..."
        parent_module(wipe=true)
        setenv!(:cur_global_ctx, nothing)
        setenv!(:cur_local_ctx,  nothing)
        δt = time() - start; @info """
            🏁 ... done $(hl(time_fmt(δt), :red))
            """
        println("")
    end
    # > deactivate env if changed
    if Pkg.project().path != old_project
        @info "🔄 reactivating your previous environment..."
        Pkg.activate(old_project)
    end
    ENV["JULIA_DEBUG"] = ""
    return
end

"""
    build(d, kw...)

Same as serve but with `final=true` by default. Note that if final is given
again in the kw then that will take precedence.
"""
build(d; kw...) = serve(d; final=true, kw...)
build(; kw...)  = serve(; final=true, kw...)


"""
    serialize_contexts(gc)

...
"""
function serialize_contexts(gc::GlobalContext)::Nothing
    start = time()

    # Create cache folder & serialise gc + all serialisable lc
    mkpath(path(gc, :cache))
    serialize_gc(gc)

    fpaths = [
        getvar(gc, :config_path, ""),
        path(gc, :folder) / "utils.jl"
    ]
    filter!(isfile, fpaths)

    for fp in fpaths
        fn = splitpath(fp)[end]
        @info "📓 keeping a copy of $(hl(fn, :cyan))..."
        cp(fp, path(gc, :cache) / fn, force=true)
    end

    δt = time() - start; @info """
        🏁 ... done $(hl(time_fmt(δt), :red))
        """
    println("")
    return
end
