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
    allow_full_skip: in the initial pass, if the config and utils haven't
                         changed since last time, allow complete skipping of
                         page builds if nothing has changed.

NOTE: it's not straightforward to parallelise this since pages can request
access to other pages' context or the global context menaing there's a fair
bit of interplay that's possible.
"""
function full_pass(
            gc::GlobalContext,
            watched_files::LittleDict{Symbol, TrackedFiles};
            # kwargs
            skip_files::Vector{Pair{String, String}}=Pair{String, String}[],
            layout_changed::Bool=false,
            config_changed::Bool=false,
            utils_changed::Bool=false,
            allow_full_skip::Bool=false,
            final::Bool=false
            )::Nothing

    initial_pass = !any((layout_changed, config_changed, utils_changed))
    final && setvar!(gc, :_final, true)

    # when resetting the context in the case of a utils change, we keep
    # track of the nb_indep_code associated with each child context so
    # it can be considered and more cells can be skipped
    bk_indep_code = LittleDict{String, LittleDict{String, CodeRepr}}()

    # depending on the case, we'll have to re-consider
    # utils or config specifically
    if initial_pass
        # discard the saved hash of files 'page.md' which depend on
        # something like 'literate.jl' which would have changed.
        # This will ensure 'pages.md' gets re-processed and considers the
        # latest 'literate.jl'.
        for rp in have_changed_deps(gc.deps_map)
            pgh = path(:cache) / noext(rp) / "pg.hash"
            rm(pgh, force=true)
        end

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

        # save independent code to allow to avoid reloading those cells
        # which are explicitly marked as independent from utils (as well
        # as from anything else).
        for (rp, c) in gc.children_contexts
            if !isempty(c.nb_code.indep_code)
                bk_indep_code[rp] = deepcopy(c.nb_code.indep_code)
            end
        end

        gc = DefaultGlobalContext()
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
    hasindex = isfile(path(:folder) / "index.md")   ||
               isfile(path(:folder) / "index.html")
    if !hasindex
        @warn """
            Full pass
            No 'index.md' or 'index.html' found in the base folder.
            There should be one though this won't block the build.
            """
    end

    # ---------------------------------------------
    println("")
    start = time(); @info """
        💡 $(hl("starting the full pass", :yellow))
        """
    println("")
    # ---------------------------------------------

    # reinstate independent code from backup (see utils changed)
    # this will only happen if bk_indep_code exists which only happens
    # if the utils have changed
    for rp in keys(bk_indep_code)
        lc = DefaultLocalContext(gc; rpath=rp)
        merge!(lc.nb_code.indep_code, bk_indep_code[rp])
        gc.children_contexts[rp] = lc
    end

    # Go over all the watched files and run `process_file` on them
    for (case, dict) in watched_files, (fp, t) in dict
        # process
        process_file(
            gc, fp, case, dict[fp];
            skip_files, initial_pass, final, allow_full_skip
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
        reprocess(r, gc;
            skip_files, final, msg="(depends on updated vars/anchors)"
        )
    end

    # RSS generation
    final && getvar(gc, :generate_rss, false) && generate_rss(gc)

    # ---------------------------------------------------------
    println("")
    δt = time() - start; @info """
        💡 $(hl("full pass done", :yellow)) $(hl(time_fmt(δt), :light_red))
        """
    println("")
    # ---------------------------------------------------------
    return
end

full_pass(watched_files::LittleDict{Symbol, TrackedFiles}; kw...) =
    full_pass(cur_gc(), watched_files, kw...)
