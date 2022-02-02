"""
    process_file(a...; kw...)

Take a file (markdown, html, ...) and process it appropriately:

* copy it "as is" in `__site`
* generate a derived file into `__site`

## Paths

    * md file
        -> process_md_file
         -> process_md_file_io!
          -> _process_md_file_html  < OR >  _process_md_file_latex

    * html file
        -> process_html_file
         -> process_html_file_io!

    * other file
        -> copy the file over

"""
function process_file(
            gc::GlobalContext,
            fpair::Pair{String,String},
            case::Symbol,
            t::Float64=0.0;             # compare modif time
            skip_files::Vector{Pair{String, String}}=Pair{String, String}[],
            initial_pass::Bool=false,
            final::Bool=false,
            reproc::Bool=false
            )
    crumbs("process_file", "$(fpair.first) => $(fpair.second)")

    # Form the full path to the file being considered
    fpath = joinpath(fpair...)

    # Check whether the file should be ignored
    # -> if it's a layout or rss file it gets processed separately
    # -> if it's marked as "to be skipped"
    skip = startswith(fpath, path(:layout)) ||  # no copy
           startswith(fpath, path(:rss))    ||  # no copy
           fpair in skip_files                     # skip
    skip && return

    # Now that we know the file should not be ignored, form the output path
    # i.e. the path where it's expected the file will be written or copied
    opath = get_opath(fpair, case)

    #
    # There are now two processing cases:
    # 1. the file is a MD or HTML file, it should be processed by Franklin to
    #    resolve Franklin-specific commands
    # 2. the file is something else (e.g. an image) then Franklin will just
    #   copy it over to the appropriate location
    #
    off = ifelse(reproc, "... ", "")
    if case in (:md, :html)
        rpath = get_rpath(fpath)
        start = time(); @info """
            $(off)⌛ processing $(hl(str_fmt(rpath), :cyan))
            """

        if case == :md
            process_md_file(gc, fpath, opath; initial_pass)

            #
            # If we're not in the initial pass, we need to reprocess all pages that
            # depend upon definitions from this page which may have changed now that
            # we just re-processed it.
            #
            if !initial_pass
                for pg in gc.children_contexts[rpath].to_trigger
                    reprocess(pg, gc; skip_files, msg="(depends on updated vars)")
                end
            end

        elseif case == :html
            process_html_file(gc, fpath, opath)
        end

        final && adjust_base_url(gc, rpath, opath)

        #
        # End of processing for MD/HTML file
        #
        ropath = "__site" / get_ropath(opath)
        @info """
            $(off)... [process] ✔ $(hl(time_fmt(time()-start))), wrote $(hl(str_fmt(ropath), :cyan))
            """

    else
        # copy the file over if
        # (A) it's not already there
        # (B) it's there but we have a more recent version that's not identical
        if !isfile(opath) || (mtime(opath) < t && !filecmp(fpath, opath))
            cp(fpath, opath, force=true)
        end
    end
    return
end

process_file(fpair::Pair{String,String}, case::Symbol, t::Float64=0.0; kw...) =
    process_file(cur_gc(), fpair, case, t; kw...)


function set_meta_parameters(lc::LocalContext, fpath::String, opath::String)
    rpath  = get_rpath(fpath)
    ropath = get_ropath(opath)
    s = stat(fpath)
    setvar!(lc, :_relative_path, rpath)
    setvar!(lc, :_relative_url, unixify(ropath))
    setvar!(lc, :_creation_time, s.ctime)
    setvar!(lc, :_modification_time, s.mtime)
end


# ------------ #
# REPROCESSING #
# ------------ #

"""
    reprocess(rpath, gc; skip_files, msg)

Re-process a md file at 'rpath'. This happens, for instance, when a page 'A.md'
has just been processed and a page 'B.md' depends upon definitions or anchors
from 'A.md'.
"""
function reprocess(
            rpath::String, gc::GlobalContext;
            skip_files::Vector{Pair{String, String}}=Pair{String,String}[],
            msg::String="",
            final::Bool=false
            )::Nothing
    # check if the file was marked as 'to be skipped'
    fpair = path(:folder) => rpath
    fpair in skip_files && return

    # otherwise reprocess the file
    case = ifelse(splitext(rpath)[2] == ".html", :html, :md)
    start = time(); @info """
        ⌛ [reprocess] $(hl(str_fmt(rpath), :cyan)) $msg
        """
    process_file(gc, fpair, case; final, reproc=true)
    δt = time() - start; @info """
        ... ✔ [reprocess] $(hl(time_fmt(δt)))
        """
    return
end


# --------------- #
# ADJUST BASE URL #
# --------------- #

"""
    adjust_base_url(gc, rpath, opath)

For a HTML file written at 'opath', replace all relative links to take the
base URL prefix (prepath) into account if it's not empty.

In such cases, erase the hash of the page as the page will need to be
re-processed in a subsequent 'serve'.
"""
function adjust_base_url(gc::GlobalContext, rpath::String, opath::String)
    #
    # If we're in the final pass, we potentially need to fix all
    # relative links to take the base_url_prefix (prepath) into
    # account.
    #
    pp = getvar(gc, :base_url_prefix, "")
    pp = strip(pp, '/')
    isempty(pp) && return

    @info """
        ... ✏ setting $(hl("base_url_prefix", :yellow)) to $(hl(pp, :yellow))...
        """
    old = read(opath, String)
    ss  = SubstitutionString("\\1=\\2/$(pp)/")
    # replace things that look like href="/..." with href="/$prepath/..."
    open(opath, "w") do outf
        write(outf, replace(old, PREPATH_FIX_PAT => ss))
    end

    # reset the page hash so that the page gets reprocessed next time
    # because now the output has links that are not in sync with the input
    gc.children_contexts[rpath].page_hash[] = hash("")
    return
end
