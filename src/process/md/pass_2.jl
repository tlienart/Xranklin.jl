"""
    process_md_file_pass_2

[threaded] iHTML to HTML. Resolve layout, DBB, pagination.
"""
function process_md_file_pass_2(
            lc::LocalContext,
            opath::String,
            final::Bool
        )::Nothing

    crumbs(@fname)

    # Note that here we must ensure that cur_lc is set
    # properly as this is called in a second phase so it's
    # not guaranteed that lc === cur_lc
    set_current_local_context(lc)

    ihtml = getvar(lc, :_generated_ihtml, "")
    odir  = dirname(opath)
    cleanup_paginated(odir)

    # NOTE:
    #  html2 done in several phases:
    #
    #   1. we resolve utils-defined hfuns since they may affect LC
    #   2. we resolve everything else --> get the body_html
    #   3. we plug the body_html in the template (either via skeleton or via
    #       head/foot), the template may itself contain dbb so we need...
    #   4. ... a final pass which will hunt for any remaining dbb and resolve.
    #   5. ... pagination token processing
    #
    body_html = ihtml2 = ""
    if getvar(lc, :_has_parser_error, false)
        # just doing damage control here
        try
            ihtml2    = html2(ihtml, lc; only_utils=true)
            body_html = html2(ihtml2, lc)
        catch
            body_html = ihtml2 = ihtml
        end
    else
        ihtml2    = html2(ihtml, lc; only_utils=true)
        body_html = html2(ihtml2, lc)
    end
    setvar!(lc, :_generated_ihtml2, ihtml2)
    setvar!(lc, :_generated_html, body_html)

    skeleton_path = path(lc.glob, :layout) / getvar(lc, :layout_skeleton, "")
    if isfile(skeleton_path) # --------------------------------------------

        full_page = read(skeleton_path, String)

    else # ----------------------------------------------------------------

        pgfoot_path = path(lc.glob, :layout) / getvar(lc, :layout_page_foot, "")
        page_foot   = isfile(pgfoot_path) ? read(pgfoot_path, String) : ""

        c_tag   = getvar(lc, :content_tag, "")
        c_class = getvar(lc, :content_class, "")
        c_id    = getvar(lc, :content_id, "")
        body    = ""

        if !isempty(c_tag)
            body = """
                <$(c_tag) $(attr(:class, c_class)) $(attr(:id, c_id))>
                  $body_html
                  $page_foot
                </$(c_tag)>
                """
        else
            body = """
                $body_html
                $page_foot
                """
        end

        head_path  = path(lc.glob, :layout) / getvar(lc.glob, :layout_head, "")
        full_page  = isfile(head_path) ? read(head_path, String) : ""
        full_page *= body
        foot_path  = path(lc.glob, :layout) / getvar(lc.glob, :layout_foot, "")
        full_page *= isfile(foot_path) ? read(foot_path, String) : ""

    end
    # ---------------------------------------------------------------------
    # process at least once, if there's a pagination token here
    # the page will be re-processed (see process_paginated)
    #
    # In the case of skeleton, this will call {{page_content}} which,
    # itself, will call html2 on :_generated_ihtml2 before it gets
    # injected in converted_html.
    #
    converted_html = ""
    if !getvar(lc, :_has_parser_error, false)
        converted_html = html2(full_page, lc)
    else
        try
            converted_html = html2(full_page, lc)
        catch
            # damage control (this would be quite an extreme and unexpected path
            # given that things should have been limited in the earlier t/c)
            converted_html = full_page
        end
    end

    process_redirect(lc, final)
    opath2 = process_slug(lc, opath)

    #
    # PAGINATION
    # > if there is pagination, we take the file at `opath` and
    # rewrite it (to resolve PAGINATOR_TOKEN) n+1 time where n is
    # the number of pages.
    # For instance if there's a pagination with effectively 3 pages,
    # then 4 pages will be written (the base page, then pages 1,2,3).
    #
    paginator_name = getvar(lc, :_paginator_name)

    if isempty(paginator_name)
        open(opath2, "w") do outf
            write(outf, converted_html)
        end
        process_not_paginated(lc.glob, lc.rpath, opath2, final)

    else
        process_paginated(lc, full_page, opath2, paginator_name, final)

    end
    return
end


"""
    from_paginated(dp)

Check if a dir can be considered as potentially coming from pagination.
To do this we check that no current local context leads to that dir.
"""
function from_paginated(dp)
    gc = cur_gc()
    for (rp, _) in gc.children_contexts
        op = get_opath(gc, path(gc, :folder) / rp)
        if occursin(dp, dirname(op))
            return false
        end
    end
    return true
end


"""
    cleanup_paginated(odir)

Remove all `odir/k/` dirs to avoid ever having spurious such dirs.
Re-creating these dirs and the file in it takes negligible time.

Note: before removing an `odir/k/` we must verify that it does not
itself correspond to a separate LC otherwise we may be erasing work
with a directory that is all numeric (for instance `news/2022/...`).
"""
function cleanup_paginated(
            odir::String
        )::Nothing

    isdir(odir) || return
    # remove all pagination folders from odir
    # we're looking for folders that look like '/1/', '/2/' etc.
    # so their name is all numeric, does not start with 0 and
    # it's a directory and does not correspond to a context --> remove
    for e in readdir(odir)
        if all(isnumeric, e) && first(e) != '0'
            dp = odir / e
            if isdir(dp) && from_paginated(dp)
                rm(dp, recursive=true)
            end
        end
    end
    return
end


"""
    process_not_paginated(gc, rpath, odir)

Handles the non-paginated case. Checks if the page was previously paginated,
if it wasn't, do nothing. Otherwise, update `gc.paginated` to reflect that
it's not paginated anymore.
"""
function process_not_paginated(
            gc::GlobalContext,
            rpath::String,
            opath::String,
            final::Bool
        )::Nothing

    rpath in gc.paginated || return
    setdiff!(gc.paginated, rpath)
    adjust_base_url(gc, rpath, opath; final)
    return
end


"""
    process_paginated(gc, rpath, opath, paginator_name)

Handles the paginated case. It takes the base file `odir/index.html` and
rewrites it to match the `/1/` case by replacing the `PAGINATOR_TOKEN`
(so `odir/index.html` and `odir/1/index.html` are identical). It then
goes on to write the other pages as needed.
"""
function process_paginated(
            lc::LocalContext,
            ctt::String,
            opath::String,
            paginator_name::String,
            final::Bool
        )::Nothing

    iter = getvar(lc, Symbol(paginator_name)) |> collect
    npp  = getvar(lc, :_paginator_npp, 10)
    odir = dirname(opath)

    # how many pages?
    niter = length(iter)
    npg = ceil(Int, niter / npp)

    # repeatedly write the content replacing the PAGINATOR_TOKEN
    for pgi = 1:npg

        # range of items we should put on page 'pgi'
        sta_i = (pgi - 1) * npp + 1
        end_i = min(sta_i + npp - 1, niter)
        rge_i = sta_i:end_i

        # form the insertion
        ins_i = prod(String(e) for e in iter[rge_i])

        # file destination
        dst = mkpath(odir / string(pgi)) / "index.html"

        # adjust lc, reset applied prefix (this is ok since we
        # did cleanup_paginated before so, in any case, we will rewrite the file)
        rurl = get_rurl(get_ropath(lc.glob, dst))

        setvar!(lc, :_relative_url, rurl)
        setvar!(lc, :_applied_base_url_prefix, "")

        # process it in the local context
        ins_i = html(ins_i, set_recursive!(lc))
        ctt_i = replace(html2(ctt, lc), PAGINATOR_TOKEN => ins_i)

        # write the file
        open(dst, "w") do f
            write(f, ctt_i)
        end

        adjust_base_url(lc.glob, lc.rpath, dst; final)
    end

    # Copy /1/ which must exists to a base (overwrite it so it has the proper inclusion)
    cp(
        odir / "1" / "index.html",
        odir / "index.html",
        force = true
    )
    return
end

"""
    process_redirect(lc)

Redirect: a URL which, when navigated to, redirects to the present page.

Expected to be in unix format. Outer forward slashes are ignored.

## Redirect examples

* aa/bb.html    --> /aa/bb.html redir
* /aa/bb.html   --> /aa/bb.html redir
* /aa/bb        --> /aa/bb/index.html redir
"""
function process_redirect(
            lc::LocalContext,
            final::Bool
        )::Nothing

    redirect = strip(getvar(lc, :redirect, ""), '/')
    if !isempty(redirect)
        if !endswith(redirect, ".html")
            redirect = noext(redirect) / "index.html"
        end
        redir_path = path(lc, :site) / redirect
        mkpath(dirname(redir_path))

        if final
            pp = getvar(lc.glob, :base_url_prefix, "")
            isempty(pp) || (pp = "/$pp")
        end
        redir_url = pp * get_rurl(lc.rpath)

        write(
            redir_path,
            """
            <!-- Generated Redirect -->
            <!doctype html>
            <html>
            <head>
                <meta http-equiv="refresh" content='0; url="$redir_url"'>
            </head>
            </html>
            """
        )
    end
    return
end


"""
    process_slug(lc)

The desired URL that should correspond to the present file.

Expected to be in unix format. Outer forward slashes are ignored.

## Slug examples

* aa/bb.html --> __site/aa/bb.html
* aa/bb/     --> __site/aa/bb/index.html
* aa/bb      --> __site/aa/bb/index.html
* /aa/bb/    --> __site/aa/bb/index.html

"""
function process_slug(
            lc::LocalContext,
            opath::String
        )::String

    slug     = strip(getvar(lc, :slug, ""), '/')
    fpath    = path(lc, :folder) / lc.rpath
    #
    # FIXME: this is the kind of place where if we have some windows-style path
    #       things can get messy as the slug is expected to be in unix format
    #       yet we're doing file system operations here.
    #       see also process_redirect
    #
    if !isempty(slug)
        if !endswith(slug, ".html")
            slug = noext(slug) / "index.html"
        end
        new_opath = path(lc, :site) / slug
        mkpath(dirname(new_opath))

        if new_opath != opath
            set_meta_parameters(lc, fpath, new_opath)
            opath = new_opath
        end
    end

    return opath
end
