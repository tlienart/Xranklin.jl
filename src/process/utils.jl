function set_meta_parameters(lc::LocalContext, fpath::String, opath::String)
    rpath  = get_rpath(lc.glob, fpath)
    ropath = get_ropath(lc.glob, opath)
    s = stat(fpath)
    setvar!(lc, :_output_path, opath)
    setvar!(lc, :_relative_path, rpath)
    setvar!(lc, :_relative_url, unixify(ropath))
    setvar!(lc, :_creation_time, s.ctime)
    setvar!(lc, :_modification_time, s.mtime)
end


"""
    adjust_base_url(lc, opath; final)
    adjust_base_url(gc, rpath, opath; final)

For a HTML file written at 'opath', replace all relative links to take the
base URL prefix (prepath) into account if it's not empty.

In such cases, erase the hash of the page as the page will need to be
re-processed in a subsequent 'serve'.
"""
function adjust_base_url(
            lc::LocalContext,
            opath::String;
            final::Bool=false
        )::Nothing
    #
    # If we're in the final pass, we potentially need to fix all
    # relative links to take the base_url_prefix (prepath) into
    # account.
    #

    pp = ifelse(final, sstrip(getvar(lc.glob, :base_url_prefix, ""), '/'), "")
    ap = getvar(lc, :_applied_base_url_prefix, "")
    pp == ap && return

    # ap will be empty if the page has not been skipped
    @info """
        ... ✏ setting $(hl("base_url_prefix", :yellow)) to $(hl(pp, :yellow))...
        """
    # replace things that look like href="/..." with href="/$prepath/..."
    old = read(opath, String)
    ss  = ifelse(isempty(pp),
        SubstitutionString("\\1=\\2/"),
        SubstitutionString("\\1=\\2/$(pp)/")
    )
    if isempty(ap)
        open(opath, "w") do outf
            write(outf, replace(old, PREPATH_FIX_PAT => ss))
        end
    elseif pp != ap
        # page has been skipped, we need to adjust the adjustment
        pat = Regex(PREPATH_FIX_PAT.pattern * "$(ap)/")
        open(opath, "w") do outf
            write(outf, replace(old, pat => ss))
        end
    end
    setvar!(lc, :_applied_base_url_prefix, pp)
    return
end

function adjust_base_url(
            gc::GlobalContext,
            rpath::String,
            opath::String;
            final::Bool=false
        )::Nothing

    lc = gc.children_contexts[rpath]
    adjust_base_url(lc, opath; final)
end
