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

[internal] perform a full pass over a set of watched files: each of these is
then processed in the `gc` context.

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
    config_changed   : whether this was triggered by a config change (or during
                        the initial pass, if the config is different than
                        a potential cached config file)
    utils_changed    : whether this was triggered by a utils change (or during
                        the initial pass, if the utils is different than
                        a potential cached utils file)
    final            : whether this is the last pass, in which case prepath
                        should be applied
"""
function full_pass(
            gc::GlobalContext,
            watched_files::Dict{Symbol,TrackedFiles};
            # kwargs
            skip_files::Vector{Pair{String,String}}=Pair{String,String}[],
            initial_pass::Bool=false,
            layout_changed::Bool=false,
            config_changed::Bool=false,
            utils_changed::Bool=false,
            final::Bool=false
        )::Nothing

    setvar!(gc, :_final, final)

    # when config and utils haven't changed, and we're on the first pass,
    # allow skipping a file if the source markdown hasn't changed, and
    # the output file is available (as it would be identical).
    # This boolean is passed further down.
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
        # save code blocks marked as independent from context to avoid having
        # to reload them.
        bk_indep_code = Dict{String,Dict{String,CodeRepr}}()
        for (rp, c) in gc.children_contexts
            if !isempty(c.nb_code.indep_code)
                bk_indep_code[rp] = deepcopy(c.nb_code.indep_code)
            end
        end
        bk_vars = deepcopy(gc.vars)

        # create new GC so that all modules can be reloaded with fresh utils
        # note that this re-creates the gc.children_contexts so effectively it
        # refreshes all contexts.
        folder = path(gc, :folder)
        gc = DefaultGlobalContext()

        set_paths!(gc, folder)
        merge!(gc.vars, bk_vars)

        activate = isfile(folder / "Project.toml") &&
                   (Pkg.project().path != getvar(gc, :project, ""))

        if activate
            Pkg.activate(folder)
            Pkg.instantiate()
            setvar!(gc, :project, Pkg.project().path)
        end

        process_utils(gc)
        process_config(gc)

        # reinstate independent code from backup
        for rp in keys(bk_indep_code)
            lc = DefaultLocalContext(gc; rpath=rp)
            merge!(lc.nb_code.indep_code, bk_indep_code[rp])
            gc.children_contexts[rp] = lc
        end

        # *all* pages will now be built from a reseted code and
        # vars module with the latest utils.

    elseif config_changed
        process_config(gc)

    end

    # now we can skip utils/config (will happen in full_pass_other)
    append!(skip_files, [
        path(:folder) => "config.md",
        path(:folder) => "utils.jl"
        ]
    )

    # check that there's an index page (this is what the server will
    # expect to point to)
    hasindex = isfile(path(:folder) / "index.md") ||
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
    start = time()
    @info """
        💡 $(hl("starting the full pass", :yellow))
        """
    println("")
    # ---------------------------------------------

    full_pass_markdown(gc,
        watched_files[:md];
        skip_files,
        allow_skip,
        final
    )
    full_pass_html(gc,
        watched_files[:html];
        skip_files,
        final
    )
    full_pass_other(gc,
        merge(watched_files[:other], watched_files[:infra]);
        skip_files
    )

    # RSS generation
    final && getvar(gc, :generate_rss, false) && generate_rss(gc)

    # ---------------------------------------------------------
    println("")
    δt = time() - start
    @info """
        💡 $(hl("full pass done", :yellow)) $(hl(time_fmt(δt), :light_red))
        """
    println("")
    # ---------------------------------------------------------
    return
end

full_pass(watched_files::Dict{Symbol,TrackedFiles}; kw...) =
    full_pass(cur_gc(), watched_files, kw...)


#= ====================================================================
Full Pass operations
--------------------

MARKDOWN (full_pass_markdown)

    1. [🔏] ensure all children_contexts are allocated
    2. [🧵] convert MD to iHTML ("pass 1")
              - check hash
              - call to convert_md
              - check anchors/tags that have changed
    3. [🔏] adjust tags, anchors in GC
    4. [🧵] convert iHTML to HTML ("pass 2")
              - resolve dbb
              - resolve pagination (XXX)
              - resolve tags       (XXX)
              - apply prefix       (XXX)
              - write to file

HTML (full_pass_html)

    1. [🔏] ensure all children_contexts are allocated
    2. [🧵] convert (i)HTML to HTML
              - resolve dbb
              - resolve pagination (XXX) (???)
              - apply prefix       (XXX)
              - write to file

OTHER (full_pass_markdown)

    1. [🧵] copy files

NOTE: threaded operations happen only if env(:use_threads)

==================================================================== =#

"""
    allocate_children_contexts(gc, watched)

[internal] for a set of watched files (either markdown or html files), check
if there's a matching context attached to GC, otherwise create one.
This is done in one batch that happens before threaded operations that would
each read/write a specific child context.
"""
function allocate_children_contexts(gc, watched)
    for (fp, _) in watched
        fpath = joinpath(fp...)
        rpath = get_rpath(gc, fpath)
        if rpath ∉ keys(gc.children_contexts)
            # just instantiating the object will append it to children contexts
            DefaultLocalContext(gc; rpath)
        end
    end
    return
end


# =======================
#                       #
#       MARKDOWN        #
#                       #
#   * _md_loop_1 (cf process/md/pass_1)
#   * _md_loop_i (cf process/md/pass_i)
#   * _md_loop_2 (cf process/md/pass_2)
#   * full_pass_markdown (wrapper)
# =======================

"""
    _md_loop_1(gc, fp, skip_dict, allow_skip)

[internal,threads] go from MD to iHTML. The main function call returns a flag
indicating whether the file was skipped (in a context where this is allowed).
This happens if the hash of the file hasn't changed nor the context.
This flag is stored in skip_dict so that any skippable file can be directly
skipped in pass 2 as well.
"""
function _md_loop_1(gc, fp, skip_dict, allow_skip)
    skip_dict[fp] && return

    fpath = joinpath(fp...)
    rpath = get_rpath(gc, fpath)
    lc = gc.children_contexts[rpath]

    skip_dict[fp] = process_md_file_pass_1(lc, fpath; allow_skip)
    return
end

"""
    _md_loop_i(gc)

[internal] go over all local contexts, check the modified anchors and tags
and adjust the gc anchors accordingly. Not threaded as writes to gc.
"""
function _md_loop_i(gc)
    for (_, lc) in gc.children_contexts
        process_md_file_pass_i(lc)
    end
    return
end

"""
    _md_loop_2(gc, fp, skip_dict)

[internal,threads] go from iHTML to HTML and correct prepath.
"""
function _md_loop_2(gc, fp, skip_dict, final)
    skip_dict[fp] && return

    fpath = joinpath(fp...)
    rpath = get_rpath(gc, fpath)
    opath = get_opath(gc, fpath)
    lc = gc.children_contexts[rpath]

    process_md_file_pass_2(lc, opath, final)
    adjust_base_url(gc, rpath, opath; final)

    return
end

"""
    full_pass_markdown(gc, watched; kw...)
"""
function full_pass_markdown(
            gc,
            watched;
            skip_files=Pair{String,String}[],
            allow_skip=false,
            final=false
            )::Nothing

    n_watched   = length(watched)
    use_threads = env(:use_threads)
    iszero(n_watched) && return
    allocate_children_contexts(gc, watched)

    # keep track of files to skip (either because marked as such
    # or because their hash hasn't changed) so that they can also
    # be skipped in pass 2.
    skip_dict = Dict(
        fp => (fp in skip_files)
        for fp in keys(watched)
    )

    # ----------------------------------------------------------------------
    @info "> Full Pass [MD/1]"
    msg(fp, n="1️⃣") = " $n ⟨$(hl(str_fmt(get_rpath(gc, joinpath(fp...)))))⟩"
    if use_threads
        entries = dic2vec(watched)
        info_thread(length(entries))
        Threads.@threads for (fp, _) in entries
            @info msg(fp)
            _md_loop_1(gc, fp, skip_dict, allow_skip)
        end
    else
        for (fp, _) in watched
            @info msg(fp)
            _md_loop_1(gc, fp, skip_dict, allow_skip)
        end
    end

    # ----------------------------------------------------------------------
    @info "> Full Pass [MD/I]"
    _md_loop_i(gc)

    # ----------------------------------------------------------------------
    @info "> Full Pass [MD/2]"
    # now all page variables are uncovered and hfuns can be resolved
    # without ambiguities. Assemble layout and iHTML, call html2 and write
    if use_threads
        entries = dic2vec(watched)
        info_thread(length(entries))
        Threads.@threads for (fp, _) in entries
            @info msg(fp, "2️⃣")
            _md_loop_2(gc, fp, skip_dict, final)
        end
    else
        for (fp, _) in watched
            @info msg(fp, "2️⃣")
            _md_loop_2(gc, fp, skip_dict, final)
        end
    end

    return
end


# ====================
#                    #
#       HTML         #
#                    #
# ====================

function _html_loop(
            gc, fp, skip_files, final
            )::Nothing

    fp in skip_files && return

    fpath = joinpath(fp...)
    opath = get_opath(gc, fpath)
    rpath = get_rpath(gc, fpath)
    lc = gc.children_contexts[rpath]

    process_html_file(lc, fpath, opath, final)
    return
end


function full_pass_html(
                gc, watched;
                # kwargs
                skip_files=Pair{String,String}[],
                final=false
            )::Nothing

    n_watched = length(watched)
    use_threads = env(:use_threads)
    iszero(n_watched) && return
    allocate_children_contexts(gc, watched)

    @info "> Full Pass [HTML]"
    if use_threads
        entries = dic2vec(watched)
        info_thread(length(entries))
        Threads.@threads for (fp, _) in entries
            _html_loop(gc, fp, skip_files, final)
        end
    else
        for (fp, _) in watched
            _html_loop(gc, fp, skip_files, final)
        end
    end
    return
end


function full_pass_other(
                gc, watched;
                # kwargs
                skip_files=Pair{String,String}[]
            )::Nothing

    n_watched = length(watched)
    iszero(n_watched) && return

    @info "> Full Pass [O]"
    entries = dic2vec(watched)
    info_thread(length(entries))
    Threads.@threads for (fp, _) in dic2vec(watched)
        fpath = joinpath(fp...)
        if fp in skip_files ||
           startswith(fpath, path(:layout)) ||
           startswith(fpath, path(:rss))

            continue
        end

        # copy the file over if it's not there in the current form
        opath = get_opath(gc, fpath)
        filecmp(fpath, opath) || cp(fpath, opath, force=true)
    end
    return
end
