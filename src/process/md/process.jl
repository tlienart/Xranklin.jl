"""
    process_md_file(...)

Note: `allow_init_skip` can only be true if we're on the very first pass and
both config and utils haven't changed. Otherwise it's always false.
"""
function process_md_file(
            lc::LocalContext,
            fpath::String,
            opath::String,
            skip_files::Vector{Pair{String, String}}=Pair{String,String}[],
            allow_init_skip::Bool=false,
            final::Bool=false
        )::Nothing

    crumbs(@fname)

    skip = process_md_file_pass_1(lc, fpath; allow_init_skip)
    skip && return

    process_md_file_pass_i(lc)
    process_md_file_pass_2(lc, opath, final)

    # check if the output path needs to be corrected to take a 'slug' into
    # account, and *copy* that file over to an additional location matching
    # that slug. The original output path is kept (this helps with skipping
    # files easily).
    opath2 = check_slug(lc, opath)

    # adjust the meta parameters associated with that context so that if,
    # for instance, a hfun requests the relative URL, it points to the
    # one matching the slug.
    if opath2 != opath
        set_meta_parameters(lc, fpath, opath2)
    end

    # process_file_from_trigger all pages that depend upon definitions from
    # this page which may have changed now that we just processed it
    # (see eval_vars_cell!)
    if !is_recursive(lc)
        for pg in lc.to_trigger
            process_file_from_trigger(
                pg, lc.glob; skip_files,
                msg="(depends on updated vars from $(lc.rpath))"
            )
        end
        empty!(lc.to_trigger)
    end
    return
end

process_md_file(gc, rpath) = begin
    fpath = path(gc, :folder) / rpath
    opath = get_opath(gc, fpath)
    lc    = rpath in keys(gc.children_contexts) ?
                gc.children_contexts[rpath]     :
                DefaultLocalContext(gc; rpath)

    process_md_file(lc, fpath, opath)
end


"""
    process_file_from_trigger(rpath, gc; skip_files, msg)

Process a md file at 'rpath' after being triggered by a dependency.
This happens, for instance, when a page 'A.md' has just been processed and a
page 'B.md' depends upon definitions or anchors from 'A.md'.

This triggering can happen in the following two situations:

1. page A.md calls a dependent file e.g. literate.jl, that file changed => A.md
    must be re-evaluated.
2. page B.md uses a variable :abc from A.md. A.md changes :abc => B.md must
    be re-evaluated.

In both situations, we discard all code pairs that are not explicitly marked as
independent 
"""
function process_file_from_trigger(
            rpath::String,
            gc::GlobalContext;
            skip_files::Vector{Pair{String, String}}=Pair{String,String}[],
            msg::String="",
            final::Bool=false
            )::Nothing
    # check if the file was marked as 'to be skipped'
    fpair = path(:folder) => rpath
    fpair in skip_files && return

    # check if the file still exists (it might have been removed e.g. in the
    # case of rm_tag_page)
    isfile(joinpath(fpair...)) || return

    # otherwise reprocess the file
    case  = ifelse(splitext(rpath)[2] == ".html", :html, :md)
    start = time(); @info """
        ⌛ [process from trigger] $(hl(str_fmt(rpath), :cyan)) $msg
        """
    process_file(gc, fpair, case; final, from_trigger=true)
    δt = time() - start; @info """
        ... ✔ [process from trigger] $(hl(time_fmt(δt)))
        """
    return
end
