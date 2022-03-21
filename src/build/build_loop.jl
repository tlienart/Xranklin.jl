
"""
    build_loop(...)
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
        redo_fullpass = false
        for d ∈ values(watched_files)
            rm_from_d = Pair{String,String}[]
            for (fp, _) in d
                fpath = joinpath(fp...)
                rpath = get_rpath(fpath)
                if !isfile(fpath)
                    push!(rm_from_d, fp)
                    # remove output files associated with fp
                    # in the case of a slug, this needs to be re-done as there
                    # will be two dependent files (one at opath, one at slug)
                    opath = get_opath(fpath)
                    isfile(opath) && rm(opath)
                    if rpath in keys(gc.children_contexts)
                        lc = gc.children_contexts[rpath]
                        if !isempty(getvar(lc, :slug, ""))
                            opath2 = getvar(lc, :_output_path, "")
                            isfile(opath2) && rm(opath2)
                        end
                        delete!(gc.children_contexts, rpath)
                        @info "❌ removed file $(hl(str_fmt(rpath), :cyan))"
                        redo_fullpass = true
                    end
                    # if the file was in the depsmap, remove it
                    delete!(gc.deps_map, rpath)
                end
            end
            for fp in rm_from_d
                delete!(d, fp)
            end
        end
        # scan the directory and add the new files to the watched_files
        _, newpg = update_files_to_watch!(watched_files, path(:folder); in_loop=true)
        # if files were deleted from the children contexts, we must
        # retrigger a full pass so that things like page lists etc are
        # properly updated; utils need to be re-evaluated to take this
        # into account.
        if redo_fullpass || newpg
            @info " → triggering full pass [page(s) added or removed]"
            full_pass(gc, watched_files; utils_changed=true)
        end

    # ========
    # BLOCK B
    # ---------------------------------------------------------------
    # Do a pass over the watched files, check if one has changed, and
    # if so, trigger the appropriate file processing mechanism
    # ---------------------------------------------------------------
    else
        for (case, d) in watched_files, (fp, t) in d
            fpath = joinpath(fp...)
            # the file may just have been deleted, it will be picked up by the
            # 'removed file' part above but in the meantime we just skip it
            isfile(fpath) || continue

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

            # if it's a dependent file
            elseif rpath in gc.deps_map.bwd_keys
                # trigger all pages that require this dependency
                for rp in gc.deps_map.bwd[rpath]
                    ft = splitdir(path(:folder) / rp)
                    fp = ft[1] => ft[2]
                    msg *= " → triggering '$rp' [dependent file changed]"; @info msg
                    process_file(gc, fp, :md, cur_t)
                end

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
