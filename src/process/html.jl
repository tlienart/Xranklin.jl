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

    crumbs(@fname, fpath)

    rpath  = get_rpath(fpath)
    in_gc  = rpath in keys(gc.children_contexts)
    lc     = in_gc ?
               gc.children_contexts[rpath] :
               DefaultLocalContext(gc; rpath)

    set_meta_parameters(lc, fpath, opath)

    open(opath, "w") do outf
        process_html_file_io!(outf, lc, fpath)
    end
    setvar!(lc, :_applied_base_url_prefix, "")
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
    if is_glob(ctx)
        set_current_global_context(ctx)
    else
        set_current_local_context(ctx)
    end

    # get html, postprocess it & write it
    write(io, html2(read(fpath, String), ctx))
    return
end
