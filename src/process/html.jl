# -------------------- #
# HTML FILE PROCESSING #
# -------------------- #

"""
    process_html_file(ctx, fpath, opath)

Process a html file located at `fpath` within context `ctx` and write the
result at `opath`.

# Note

In general the context is a global one, apart from when it's triggered from
an 'insert' in which case it will be the current active context.
See `process_html_file_io!`.
"""
function process_html_file(
            ctx::Context,
            fpath::String,
            opath::String
            )
    crumbs("process_html_file", fpath)
    open(opath, "w") do outf
        process_html_file_io!(outf, ctx, fpath)
    end
    return
end

"""
    process_html_file_io!(io, ctx, fpath)

Process a html file located at `fpath` within context `ctx` and write the
result to the io stream `io` (this always writes to `io`).
"""
function process_html_file_io!(
            io::Union{IOStream, IOBuffer},
            ctx::Context,
            fpath::String
            )
    # ensure we're in the relevant context
    if isglob(ctx)
        set_current_global_context(gc)
    else
        set_current_local_context(ctx)
    end

    # get html, postprocess it & write it
    write(io, html2(read(fpath, String), ctx))
    return
end
