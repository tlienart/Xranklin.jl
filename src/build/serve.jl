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
    single (Bool): do a single build pass and stop.

### LiveServer arguments

    port (Int): port to use for the local server.
    host (String): host to use for the local server.
    launch (Bool): whether to launch the browser once the site is built and
                   ready to be viewed. A user who has interrupted a previous
                   `serve` might prefer to set this to `false` as they might
                   already have a browser tab pointing to a page of interest.

"""
function serve(;
            folder::String      = pwd(),
            clear::Bool         = false,
            single::Bool        = true,
            # LiveServer options
            port::Int           = 8000,
            host::String        = "127.0.0.1",
            launch::Bool        = true,
            )

    gc = DefaultGlobalContext()
    set_paths!(gc, folder)

    # check if there's a config file and process it, this must happen prior
    # to everything as it defines 'ignore' for instance which is needed in
    # the watched_files step
    process_config(gc)

    # scrape the folder for files to watch
    watched_files = find_files_to_watch(folder)

    # activate the folder environment if there is one
    project_file  = path(:folder)/"Project.toml"
    if isfile(project_file)
        Pkg.activate(project_file)
    end

    # do the initial build
    full_pass(watched_files; gc=gc, initial_pass=true)

    # ---------------------------------------------------------------
    # Start the build loop
    if !single
        @info "Starting the server"
        loop = (cntr, watcher) -> build_loop(cntr, watcher, watched_files)
        # start LiveServer
        LiveServer.serve(
            port=port,
            coreloopfun=loop,
            dir=path(:site),
            host=host,
            launch_browser=launch
        )
    end

    # ---------------------------------------------------------------
    # Cleanup:
    # > wipe parent module (make all children modules inaccessible
    #   so that the garbage collector should be able to destroy them)
    parent_module(wipe=true)
    # > deactivate env
    Pkg.activate()
    return
end


"""
    full_pass(watched_files; kw...)

Perform a full pass over a set of watched files: each of these is then
processed in the `gc` context.

DEV NOTE: we could use multithreadding here but the overhead for a typical
website compared to how much time it takes to do things sequentially is
prohibitive. It would be much better to invest in saving a previous context
for warm-loading.

## KW-Args

    gc:           global context in which to do the full pass
    skip:         list of file pairs to ignore in the pass
    initial_pass: whether it's the first pass, in that case there can be
                    situations where we want to avoid double-processing some
                    md files. E.g. if A requests a var from B, then A will
                    trigger the processing of B and we shouldn't do B again.
                    See process_md_file and getvarfrom.
"""
function full_pass(
            watched_files::LittleDict{Symbol, TrackedFiles};
            gc::GlobalContext=cur_gc(),
            skip_files::Vector{Pair{String, String}}=Pair{String, String}[],
            initial_pass::Bool=false
            )::Nothing
    # make sure the context considers the config file
    process_config(gc)

    # check that there's an index page (this is what the server will
    # expect to point to)
    hasindex = isfile(path(:folder)/"index.md") ||
               isfile(path(:folder)/"index.html")
    if !hasindex
        @warn """
            Full pass
            ---------
            No 'index.md' or 'index.html' found in the base folder.
            There should be one though this won't block the generation.
            """
    end

    # Go over all the watched files and run `process_file` on them.
    start = time(); @info """
        💡 $(hl("starting the full pass", :yellow))
        """
    # NOTE: it's not straightforward to parallelise this, pages can request
    # access to other pages' context or the global context so there's a fair
    # bit of interplay that's possible; we can't guarantee runs will be indep
    for (case, dict) in watched_files, (fp, t) in dict
        process_file(fp, case, dict[fp];
                     gc=gc, skip_files=skip_files, initial_pass=initial_pass)
    end
    δt = time() - start; @info """
        💡 $(hl("full pass done", :yellow)) $(hl(time_fmt(δt)))
        """

    # Collect the pages that may need re-processing if they depend on definitions
    # that got updated in the meantime.
    # We can ignore gc because we just did a full pass
    empty!(gc.to_trigger)
    re_process = gc.to_trigger
    for c in values(gc.children_contexts)
        union!(re_process, c.to_trigger)
        empty!(c.to_trigger)
    end
    for rpath in re_process
        start = time(); @info """
        ⌛ re-processing $(hl(rpath)) as it depends on things that were updated...
        """
        process_md_file(gc, rpath)
        δt = time() - start; @info """
        ... ✔ [reproccess] $(hl(time_fmt(δt)))
        """
    end
    return
end


#=
NOTE

loop
- use prune_children!

=#
"""
"""
function build_loop(
            cycle_counter::Int,
            ::LiveServer.FileWatcher,
            watched_files::LittleDict{Symbol, TrackedFiles}
            )::Nothing
    # every 30 cycles (3 seconds), scan directory to check for new
    # or deleted files and update accordingly
    if mod(cycle_counter, 30) == 0
        # 1. check if some files have been deleted; note that we
        # don't do anything, we just remove the file reference
        for d ∈ watched_files
        end
    else
    end
end
