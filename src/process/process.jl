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
            reproc::Bool=false,
            allow_skip::Bool=false
        )::Nothing

    crumbs(@fname, "$(fpair.first) => $(fpair.second)")

    # Form the full path to the file being considered
    fpath = joinpath(fpair...)

    # Check whether the file should be ignored
    # -> if it's a layout or rss file it gets processed separately
    # -> if it's marked as "to be skipped"
    skip = startswith(fpath, path(:layout)) ||  # no copy
           startswith(fpath, path(:rss))    ||  # no copy
           fpair in skip_files                  # skip
    skip && return

    # Now that we know the file should not be ignored, form the output path
    # i.e. the path where it's expected the file will be written or copied
    opath = get_opath(gc, fpair, case)
    #
    # There are now two processing cases:
    # 1. the file is a MD or HTML file, it should be processed by Franklin to
    #    resolve Franklin-specific commands
    # 2. the file is something else (e.g. an image) then Franklin will just
    #   copy it over to the appropriate location
    #
    off = ifelse(reproc, "... ", "")
    if case in (:md, :html)
        rpath = get_rpath(gc, fpath)
        lc    = get(gc.children_contexts, rpath, DefaultLocalContext(gc; rpath))

        if case == :md
            process_md_file(lc, fpath, opath, skip_files, allow_skip, final)

        elseif case == :html
            process_html_file(lc, fpath, opath, final)

        end

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
