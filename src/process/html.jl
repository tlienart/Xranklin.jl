# -------------------- #
# HTML FILE PROCESSING #
# -------------------- #

"""
    process_html_file(ctx, fpath, opath)

Process a html file located at `fpath` within context `ctx` and write the
result at `opath`.

# Note


"""
function process_html_file(
            gc::GlobalContext,
            fpath::String,
            opath::String
            )::Nothing
    crumbs("process_html_file", fpath)

    rpath  = get_rpath(fpath)
    ropath = get_ropath(opath)
    in_gc  = rpath in keys(gc.children_contexts)
    lc     = in_gc ?
               gc.children_contexts[rpath] :
               DefaultLocalContext(gc; rpath)

    # set meta parameters
    s = stat(fpath)
    setvar!(lc, :_relative_path, rpath)
    setvar!(lc, :_relative_url, unixify(ropath))
    setvar!(lc, :_creation_time, s.ctime)
    setvar!(lc, :_modification_time, s.mtime)

    open(opath, "w") do outf
        process_html_file_io!(outf, lc, fpath)
    end
    return
end

"""
    process_html_file_io!(io, ctx, fpath)

Process a html file located at `fpath` within context `ctx` and write the
result to the io stream `io` (this always writes to `io`).

Note that in the case of `hfun_insert`, the context is the current active
context. See `hfun_insert`.
"""
function process_html_file_io!(
            io::Union{IOStream, IOBuffer},
            ctx::Context,
            fpath::String
            )

    # ensure we're in the relevant context
    if isglob(ctx)
        set_current_global_context(ctx)
    else
        set_current_local_context(ctx)
    end

    # get html, postprocess it & write it
    write(io, html2(read(fpath, String), ctx))
    return
end
