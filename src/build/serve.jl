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
function serve(d::String   = pwd();
            dir::String    = d,
            folder::String = dir,
            clear::Bool    = false,
            single::Bool   = false,
            # Debugging options
            debug::Bool   = false,
            cleanup::Bool = true,
            # LiveServer options
            port::Int    = 8000,
            host::String = "127.0.0.1",
            launch::Bool = true,
            )

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

    # if clear, destroy output directories if any
    if clear
        for odir in (path(:site), path(:pdf), path(:cache))
            rm(odir; force=true, recursive=true)
        end
    end

    # check if there's a utils/config file and process, this must happen
    # prior to everything as it defines 'ignore' for instance which is
    # needed in the watched_files step
    # NOTE: if utils has changed, everything will be wiped as well given that
    # utils is potentially loaded everywhere. See process_utils. This is why
    # process_utils returns a GC which might be different
    process_utils(gc)
    process_config(gc)

    # scrape the folder to collect all files that should be watched for
    # changes; this set will be updated in the loop if new files get
    # added that should be watched
    wf = find_files_to_watch(folder)

    # activate the folder environment if there is one
    project_file  = path(:folder) / "Project.toml"
    if isfile(project_file)
        Pkg.activate(project_file)
    end

    # do the initial build
    full_pass(gc, wf)

    # ---------------------------------------------------------------
    # Start the build loop
    if !single
        loop = (cntr, watcher) -> build_loop(cntr, watcher, wf)
        # start LiveServer
        LiveServer.serve(
            port=port,
            coreloopfun=loop,
            dir=path(:site),
            host=host,
            launch_browser=launch
        )
        println("") # skip a line to pass the '^C' character
    end

    # ---------------------------------------------------------------
    # Finalize
    # > go through every page and serialize them; this only needs
    # to be done at the end. For the global setting, we don't
    # serialize the code notebook (utils) since it always needs to be
    # re-evaluated at the start.
    start = time()
    @info "📓 serializing $(hl("config", :cyan))..."
    serialize_notebook(gc.nb_vars, path(:cache) / "gnbv.cache")
    for (rp, ctx) in gc.children_contexts
        # ignore .html pages
        endswith(rp, ".md") || continue
        @info "📓 serializing $(hl(str_fmt(rp), :cyan))..."
        serialize_notebook(ctx.nb_vars, path(:cache) / noext(rp) / "nbv.cache")
        serialize_notebook(ctx.nb_code, path(:cache) / noext(rp) / "nbc.cache")
    end
    δt = time() - start; @info """
        💡 $(hl("serializing done", :yellow)) $(hl(time_fmt(δt)))
        """

    # ---------------------------------------------------------------
    # Cleanup:
    # > wipe parent module (make all children modules inaccessible
    #   so that the garbage collector should be able to destroy them)
    # > unlink global and local context so that the gc can destroy them.
    if cleanup
        start = time()
        @info "❌ cleaning up all objects"
        parent_module(wipe=true)
        setenv!(:cur_global_ctx, nothing)
        setenv!(:cur_local_ctx,  nothing)
        δt = time() - start; @info """
            💡 $(hl("cleaning up done", :yellow)) $(hl(time_fmt(δt)))
            """
    end
    # > deactivate env
    Pkg.activate()
    ENV["JULIA_DEBUG"] = ""
    return
end


"""
    full_pass(watched_files; kw...)

Perform a full pass over a set of watched files: each of these is then
processed in the `gc` context.

This can happen in the following situations (see `build_loop`)

1. the initial start of the server (GC is fresh)
2. if a layout HTML file was changed (e.g. '_layout/head.html')
3. if config.md changed
4. if utils.jl changed

In the last case, the GC is reinstantiated so that all children contexts get
re-instantiated from scratch, reloading Utils at the start. This is important
since any code cell might call from Utils and we don't know which ones do.

## KW-Args

    gc:           global context in which to do the full pass
    skip_files:   list of file pairs to ignore in the pass
    layout_changed: whether this was triggered by a layout change
    config_changed: whether this was triggered by a config change
    utils_changed: whether this was triggered by a utils change

NOTE: it's not straightforward to parallelise this since pages can request
access to other pages' context or the global context menaing there's a fair
bit of interplay that's possible.
"""
function full_pass(
            gc::GlobalContext,
            watched_files::LittleDict{Symbol, TrackedFiles};
            skip_files::Vector{Pair{String, String}}=Pair{String, String}[],
            layout_changed::Bool=false,
            config_changed::Bool=false,
            utils_changed::Bool=false
            )::Nothing

    initial_pass = !any((layout_changed, config_changed, utils_changed))

    # depending on the case, we'll have to re-consider
    # utils or config specifically
    if initial_pass
        process_utils(gc)
        process_config(gc)

    elseif config_changed
        # just reconsider config
        process_config(gc)

    elseif utils_changed
        # create new GC so that all modules can be reloaded with utils
        # reinstantiate the global context specifically so that all children
        # modules are re-loaded with the refreshed utils
        # NOTE: it's needed to wipe the gc modules and to do that to instantiate
        # a new GC as the utils.jl might have removed some signatures which then
        # can't be used anymore. (e.g. if Foo was defined then removed).
        folder = path(:folder)
        gc     = DefaultGlobalContext()
        set_paths!(gc, folder)

        process_utils(gc)
        process_config(gc)
    end
    # NOTE: the case layout_changed -- we don't need to re-check config/utils

    # now we can skip utils/config
    append!(skip_files, [
        path(:folder) => "config.md",
        path(:folder) => "utils.jl"
        ]
    )

    # check that there's an index page (this is what the server will
    # expect to point to)
    hasindex = isfile(path(:folder)/"index.md") ||
               isfile(path(:folder)/"index.html")
    if !hasindex
        @warn """
            Full pass
            No 'index.md' or 'index.html' found in the base folder.
            There should be one though this won't block the build.
            """
    end

    # ---------------------------------------------
    start = time(); @info """
        💡 $(hl("starting the full pass", :yellow))
        """
    # ---------------------------------------------

    # Go over all the watched files and run `process_file` on them
    for (case, dict) in watched_files, (fp, t) in dict
        process_file(
            gc, fp, case, dict[fp];
            skip_files, initial_pass
        )
    end

    # REPROCESSING (2nd pass)
    # -----------------------
    # Collect the pages that may need re-processing if they depend on
    # definitions that got updated in the pass.
    # This is for all the cross pages dependencies (e.g. if page A
    # depends on a var that's defined in B that was seen after).
    # GC triggers can be ignored here because we just did a full pass.
    empty!(gc.to_trigger)
    to_reprocess = Set{String}()
    # cross pages dependencies (via getvarfrom)
    for c in values(gc.children_contexts)
        union!(to_reprocess, c.to_trigger)
        empty!(c.to_trigger)
    end
    # global init dependencies such as anchors
    if initial_pass
        union!(to_reprocess, gc.init_trigger)
    end
    # reprocess
    for r in to_reprocess
        reprocess(r, gc; skip_files, msg="(depends on updated vars/anchors)")
    end

    # ---------------------------------------------------------
    δt = time() - start; @info """
        💡 $(hl("full pass done", :yellow)) $(hl(time_fmt(δt)))
        """
    # ---------------------------------------------------------
    return
end

full_pass(watched_files::LittleDict{Symbol, TrackedFiles}; kw...) =
    full_pass(cur_gc(), watched_files, kw...)


"""
"""
function build_loop(
            cycle_counter::Int,
            ::LiveServer.FileWatcher,
            watched_files::LittleDict{Symbol, TrackedFiles}
            )::Nothing

    # Ensure to have the latest, up-to-date global context
    # NOTE: this might seem a bit weird (instead of passing a long-standing object
    # as part of the args of build_loop) but there's a subtlety: when utils.jl changes
    # it basically re-triggers a full-build because Utils is potentially involved
    # everywhere. So calling the cur_gc here ensures that upon any trigger we always
    # take the latest (which, as was unfortunately experimented, was otherwise not
    # guaranteed) See also full_pass.
    gc = cur_gc()
    # ========
    # BLOCK A
    # ---------------------------------------------------------------
    # Regularly refresh the set of "watched_files" by re-scraping
    # the folder in search of new files to watch or files that
    # might have been deleted and don't need to be watched anymore
    # ---------------------------------------------------------------
    if mod(cycle_counter, 30) == 0
        # check if some files have been deleted; if so remove the ref
        # to that file from the watched files and the gc children if
        # it's one of the child page.
        for d ∈ values(watched_files), (fp, _) in d
            fpath = joinpath(fp...)
            rpath = get_rpath(fpath)
            if !isfile(fpath)
                delete!(d, fp)
                delete!(gc.children_contexts, rpath)
            end
        end
        # scan the directory and add the new files to the watched_files
        update_files_to_watch!(watched_files, path(:folder); in_loop=true)

    # ========
    # BLOCK B
    # ---------------------------------------------------------------
    # Do a pass over the watched files, check if one has changed, and
    # if so, trigger the appropriate file processing mechanism
    # ---------------------------------------------------------------
    else
        for (case, d) in watched_files, (fp, t) in d
            fpath = joinpath(fp...)
            rpath = get_rpath(fpath)
            # was there a modification to the file? otherwise skip
            cur_t = mtime(fpath)
            cur_t <= t && continue

            # update the modif time of that file & mark it for reprocessing
            msg   = "💥 file $(hl(str_fmt(rpath), :cyan)) changed"
            d[fp] = cur_t

            # ===================
            # FULLPASS TRIGGERS =
            # ===================

            # if it's a `_layout` file that was changed, then we need to process
            # all `.md` and `.html` files
            if case == :infra && endswith(fpath, ".html")
                # ignore all files that are not directly mapped to an output file
                skip_files = [
                    k for k in keys(d)
                    for (case, d) ∈ watched_files if case ∉ (:md, :html)
                ]
                msg *= " → triggering full pass [layout changed]"; @info msg
                full_pass(gc, watched_files; skip_files, layout_changed=true)

            # config chagned
            elseif fpath == path(:folder) / "config.md"
                msg *= " → triggering full pass [config changed]"; @info msg
                full_pass(gc, watched_files; config_changed=true)

            elseif fpath == path(:folder) / "utils.jl"
                msg *= " → triggering full pass [utils changed]"; @info msg
                # NOTE in this case gc is re-instantiated!
                full_pass(gc, watched_files; utils_changed=true)

            # xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
            # TODO
            #  - special case for literate or pluto or weave files
            # (see Franklin)
            # # xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

            # it's a standard file, process just that one
            else
                @info msg
                process_file(gc, fp, case, cur_t)
            end

            @info "✅  Website updated and ready to view"
        end
    end
    return
end
