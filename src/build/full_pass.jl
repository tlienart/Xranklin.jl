#=
full pass can be triggered by

1. initial pass
    1.a without cache
    1.b with cache
2. change of layout file(s)
3. config file changed
4. utils file changed

In the full pass, there are two phases that must happen in sequence
though internally each phase can happen in parallel.

Phase A (all pages) [case 1, 3, 4]

    - build page content (MD -> HTML_1) ignoring layout and {{...}}

Phase B (all pages) [all cases]
    - HTML1 -> HTML2

NOTE on assumptions

    * at most depth 1, meaning that a page A can request a variable from
        page B through a {{...}} call BUT that variable on page B cannot
        itself be requested from another page.
        So A <- B is allowed but not A <- B <- C (or deeper).

=#

"""
    full_pass(watched_files; kw...)

Perform a full pass over a set of watched files: each of these is then
processed in the `gc` context.

This can happen in the following situations (see `build_loop`)

1. the initial start of the server (GC is fresh)
2. layout HTML file was changed (e.g. '_layout/head.html')
3. config file was changed
4. utils file was changed

In case (4), the GC is reinstantiated so that all children contexts get
re-instantiated from scratch, reloading Utils at the start.
This is important since any code cell might call from Utils and we don't know
which ones do.

## KW-Args

    gc               : global context in which to do the full pass
    skip_files       : list of file pairs to ignore in the pass
    initial_pass     : whether the call is from the initial build
    layout_changed   : whether this was triggered by a layout change
    config_changed   : whether this was triggered by a config change
    utils_changed    : whether this was triggered by a utils change
    final            : whether this is the last pass, in which case prepath
                        should be applied
"""
function full_pass(
            gc::GlobalContext,
            watched_files::Dict{Symbol, TrackedFiles};
            # kwargs
            skip_files::Vector{Pair{String, String}}=Pair{String, String}[],
            initial_pass::Bool   = false,
            layout_changed::Bool = false,
            config_changed::Bool = false,
            utils_changed::Bool  = false,
            final::Bool          = false
            )::Nothing

    final && setvar!(gc, :_final, true)

    # when config and utils haven't changed and we're on the first pass,
    # allow skipping a file if the source markdown hasn't changed and the output
    # file is available
    allow_skip = initial_pass & !(config_changed | utils_changed)

    if initial_pass
        # check if dependent files (e.g. literate files) have changed and,
        # if so, discard the hash of pages which would depend upon those
        # to guarantee that they're reprocessed and consider the latest
        # dependent file.
        for rp in have_changed_deps(gc.deps_map)
            pgh = path(:cache) / noext(rp) / "pg.hash"
            rm(pgh, force=true)
        end
    end

    if utils_changed
        # save independent code to allow to avoid reloading those cells
        # which are explicitly marked as independent from utils (as well
        # as from anything else).
        bk_indep_code = Dict{String, Dict{String, CodeRepr}}()
        for (rp, c) in gc.children_contexts
            if !isempty(c.nb_code.indep_code)
                bk_indep_code[rp] = deepcopy(c.nb_code.indep_code)
            end
        end

        # create new GC so that all modules can be reloaded with fresh utils
        gc = DefaultGlobalContext()
        set_paths!(gc, path(:folder))

        process_utils(gc)
        process_config(gc)

        # reinstate independent code from backup
        for rp in keys(bk_indep_code)
            lc = DefaultLocalContext(gc; rpath=rp)
            merge!(lc.nb_code.indep_code, bk_indep_code[rp])
            gc.children_contexts[rp] = lc
        end

    elseif config_changed
        process_config(gc)
    end

    # now we can skip utils/config (will happen in process_all_other_files)
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

    process_all_md_files(
        gc, watched_files[:md];
        skip_files, allow_skip
    )
    process_all_html_files(
        gc, watched_files[:html];
        skip_files
    )
    process_all_other_files(
        merge(watched_files[:other], watched_files[:infra]);
        skip_files
    )

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

full_pass(watched_files::Dict{Symbol, TrackedFiles}; kw...) =
    full_pass(cur_gc(), watched_files, kw...)


# =================================
# MD FILES
#   pass 1: md    -> ihtml
#   pass 2: ihtml -> html
# =================================
function process_all_md_files(
            gc, watched;
            skip_files,
            allow_skip
        )::Nothing

    n_watched = length(watched)

    # assign all entries in gc.children_contexts so that each thread
    # touches an already-assigned object
    for (fp, _) in watched
        fpath = joinpath(fp...)
        rpath = get_rpath(gc, fpath)
        if rpath ∉ keys(gc.children_contexts)
            # just instantiating the object will append it to children contexts
            DefaultLocalContext(gc; rpath)
        end
    end

    # keep track of files to skip (either because marked as such
    # or because their hash hasn't changed) so that they can also
    # be skipped in pass 2.
    skip_dict = Dict(fp => fp in skip_files for fp in keys(watched))

    @info "> Full Pass (md files pass 1, threaded)"
    # XXX Threads.@threads for (fp, _) in watched
    for (fp, _) in watched
        skip_dict[fp] && continue

        fpath = joinpath(fp...)
        rpath = get_rpath(gc, fpath)

        @show rpath

        lc    = gc.children_contexts[rpath]

        # convert from MD to iHTML, if the page should be skipped because
        # nothing changed, keep track of that in skip_dict
        skip_dict[fp] = process_md_file_pass_1(lc, fpath; allow_skip)
    end

    @info "> Full pass (intermediate step, unthreaded)"
    # Go over all local contexts, check the modified anchors and adjust the
    # gc anchors accordingly. Not threaded as everything accesses gc.anchor.
    for (rpath, lc) in gc.children_contexts
        # Anchors
        default = Set{String}()
        for id in getvar(lc, :_rm_anchors, default)
            rm_anchor(gc, id, rpath)
        end
        setvar!(lc, :_rm_anchors, default)

        # Tags to remove
        for id in getvar(lc, :_rm_tags, default)
            rm_tag(gc, id, rpath)
        end
        setvar!(lc, :_rm_tags, default)

        # Tags to add
        default = Vector{Pair{String}}()
        for (id, name) in getvar(lc, :_add_tags, default)
            add_tag(gc, id, name, rpath)
        end
        setvar!(lc, :_add_tags, default)
    end

    @info "> Full Pass (md files pass 2, threaded)"
    # now all page variables are uncovered and hfuns can be resolved
    # without ambiguities. Assemble layout and iHTML, call html2 and write
    # XXX Threads.@threads for (fp, _) in watched
    for (fp, _) in watched
        skip_dict[fp] && continue

        fpath = joinpath(fp...)
        rpath = get_rpath(gc, fpath)

        @show rpath

        opath = get_opath(fpath)
        lc    = gc.children_contexts[rpath]
        process_md_file_pass_2(lc, opath)
    end
    return
end


function process_all_html_files(
            gc, watched;
            skip_files
            )::Nothing

    n_watched = length(watched)
    iszero(n_watched) && return

    @info "Full Pass (html files)"
    # XXX Threads.@threads for (fp, _) in watched
    for (fp, _) in watched
        fp in skip_files && continue

        fpath = joinpath(fp...)
        opath = get_opath(fpath)
        rpath = get_rpath(gc, fpath)

        process_html_file(gc, fpath, opath)
        adjust_base_url(gc, rpath, opath; final)
    end
    return
end


function process_all_other_files(
            watched;
            skip_files
        )::Nothing

    n_watched = length(watched)
    iszero(n_watched) && return

    @info "Full Pass (other files)"
    # XXX Threads.@threads for (fp, _) in watched
    for (fp, _) in watched
        fpath = joinpath(fp...)
        if fp in skip_files ||
             startswith(fpath, path(:layout)) ||
             startswith(fpath, path(:rss))

            continue
        end

        # copy the file over if it's not there in the current form
        opath = get_opath(fpath)
        filecmp(fpath, opath) || cp(fpath, opath, force=true)
    end

    return
end
