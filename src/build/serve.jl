"""
    serve(; kw...)

Runs Franklin in the current directory.

## Keyword Arguments

    folder (String): website folder, this is the folder which is expected to
                     contain the config.md as well as the index.(md|html).
    clear (Bool): whether to clear everything and start from scratch, this
                  will clear the `__site`, `__cache` and `__pdf` directories.
                  This can be used when something got corrupted e.g. by
                  having inadvertently modified files in one of those folders
                  or if somehow a lot of stale files accumulated in one of
                  these folders.
    final (Bool): whether it's the build (e.g. for CI or publication), in this
                  case all links are adjusted to reflect the 'prepath'.
    single (Bool): do a single build pass and stop.

    prepath/prefix/base_url_prefix: override the base url prefix (e.g. from
                                    the deploy.yml.

### Debugging options

    debug (Bool): whether to display debugging messages.
    cleanup (Bool): whether to destroy the context objects, when debugging this
                    can be useful to explore local and global variables.

### LiveServer arguments

    port (Int): port to use for the local server.
    host (String): host to use for the local server.
    launch (Bool): whether to launch the browser once the site is built and
                   ready to be viewed. A user who has interrupted a previous
                   `serve` might prefer to set this to `false` as they might
                   already have a browser tab pointing to a page of interest.

"""
function serve(d::String = "";

            # Main kwargs
            dir::String    = d,
            folder::String = dir,
            clear::Bool    = false,
            final::Bool    = false,
            single::Bool   = final,

            # Base url prefix / prepath optional override
            prepath::String = "",
            prefix::String = "",
            base_url_prefix::String = ifelse(isempty(prepath), prefix, prepath),

            # Debugging options
            debug::Bool   = false,
            cleanup::Bool = true,

            # LiveServer options
            port::Int    = 8000,
            host::String = "127.0.0.1",
            launch::Bool = true,
            )

    folder = ifelse(isempty(folder), pwd(), dir)

    if debug
        Logging.disable_logging(Logging.Debug - 100)
        ENV["JULIA_DEBUG"] = "all"
    else
        ENV["JULIA_DEBUG"] = ""
    end

    # Instantiate the global context, this also creates a global vars and code
    # notebooks which each have their module. The first creation of a module
    # will also create the overall `parent_module` in which all modules (for
    # both the global and the local contexts) will live.
    gc = DefaultGlobalContext()
    set_paths!(gc, folder)

    # if there is a utils.jl that was cached, check if it has changed,
    # if it has, we clear even if clear is false
    cached  = path(:cache)  / "utils.jl"
    current = path(:folder) / "utils.jl"

    # if clear, destroy output directories if any
    if clear || (any(isfile, (cached, current)) && !filecmp(cached, current))
        for odir in (path(:site), path(:pdf), path(:cache))
            rm(odir; force=true, recursive=true)
        end
    else
        start = time()
        # try to load previously-serialised contexts if any
        isfile(gc_cache_path()) && deserialize_gc(gc)
        δt = time() - start; @info """
            💡 $(hl("de-serialization done", :yellow)) $(hl(time_fmt(δt), :red))
            """
    end

    # check if there's a config file and process it, this must happen
    # prior to everything as it defines 'ignore' for instance which is
    # needed in the watched_files step
    process_config(gc)
    isempty(base_url_prefix) || setvar!(gc, :base_url_prefix, base_url_prefix)

    # scrape the folder to collect all files that should be watched for
    # changes; this set will be updated in the loop if new files get
    # added that should be watched
    wf = find_files_to_watch(folder)

    # activate the folder environment
    pf = path(:folder)
    if isfile(pf / "Project.toml")
        Pkg.activate(pf)
        Pkg.instantiate()
    end

    # do the initial build
    process_utils(gc)
    full_pass(gc, wf; final)

    # ---------------------------------------------------------------
    # Start the build loop unless we're in single pass mode (single)
    # or in final build mode (final).
    if !any((single, final))
        loop = (cntr, watcher) -> build_loop(cntr, watcher, wf)
        # start LiveServer
        LiveServer.serve(
            port           = port,
            coreloopfun    = loop,
            dir            = path(:site),
            host           = host,
            launch_browser = launch
        )
        println("") # skip a line to pass the '^C' character
    end

    # ---------------------------------------------------------------
    # Finalise by caching notebooks etc
    serialize_contexts(gc)

    # ---------------------------------------------------------------
    # Cleanup:
    # > wipe parent module (make all children modules inaccessible
    #   so that the garbage collector should be able to destroy them)
    # > unlink global and local context so that the gc can destroy them.
    if cleanup
        start = time()
        @info "🗑️ cleaning up all objects"
        parent_module(wipe=true)
        setenv!(:cur_global_ctx, nothing)
        setenv!(:cur_local_ctx,  nothing)
        δt = time() - start; @info """
            💡 $(hl("cleaning up done", :yellow)) $(hl(time_fmt(δt), :red))
            """
        println("")
    end
    # > deactivate env
    Pkg.activate()
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
    mkpath(path(:cache))
    serialize_gc(gc)

    # if utils changes from one to next, amounts to "clear"
    futils = path(:folder) / "utils.jl"
    if isfile(futils)
        @info "📓 keep copy of $(hl("utils", :cyan))..."
        cp(futils, path(:cache) / "utils.jl", force=true)
    end

    δt = time() - start; @info """
        💡 $(hl("serializing done", :yellow)) $(hl(time_fmt(δt), :red))
        """
    println("")
    return
end
