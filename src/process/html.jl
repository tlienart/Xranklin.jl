"""
    process_html_file(ctx, fpath, opath)

Process a html file located at `fpath` within context `ctx` and write the
result at `opath`.
"""
function process_html_file(
            lc::LocalContext,
            fpath::String,
            opath::String,
            final::Bool
        )::Nothing

    crumbs(@fname, fpath)

    set_meta_parameters(lc, fpath, opath)
    open(opath, "w") do outf
        write(
            outf,
            html2(read(fpath, String), lc)
        )
    end
    adjust_base_url(lc.glob, lc.rpath, opath; final)
    return
end
