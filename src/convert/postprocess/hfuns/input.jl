#=

FILL
INSERT / INCLUDE

=#


"""
    {{fill x}}
    {{fill x from}}

Write the value of variable `x` from either the local context or the context
of the page at `from`.

See also `_dbb_fill` (called from `{{varname}}`).
"""
function hfun_fill(
            lc::LocalContext,
            p::VS;
            tohtml=true
        )::String

    c = _hfun_check_nargs(:fill, p; kmin=1, kmax=2)
    isempty(c) || return c

    np  = length(p)
    out = (np == 1) ? _hfun_fill_1(lc, p) : _hfun_fill_2(lc, p)
    return out
end

"Helper function for case `{{fill x}}`"
function _hfun_fill_1(
            lc::LocalContext,
            p::VS
        )::String

    vname = Symbol(p[1])
    if (v = getvar(lc, vname)) !== nothing
        return stripped_repr(v)
    elseif vname in utils_var_names(lc.glob)
        mdl = cur_gc().nb_code.mdl
        return stripped_repr(getproperty(mdl, vname))
    else
        @warn """
            {{fill $vname}}
            The variable $vname does not match a variable in the context,
            inserting an empty string instead.
            """
        return ""
    end
end

"""
Helper function for case `{{fill x from}}`
"""
function _hfun_fill_2(
            lc::LocalContext,
            p::VS
        )::String

    vname = Symbol(p[1])
    rpath = strip(p[2], '/')
    endswith(rpath, ".md") || (rpath *= ".md")
    gc = cur_gc()
    has_var = rpath in keys(gc.children_contexts) &&
              vname in keys(gc.children_contexts[rpath].vars)
    if has_var
        v = getvar(
                gc.children_contexts[rpath],
                lc,
                vname
            )
        return stripped_repr(v)
    else
        @warn """
            {{fill $vname $rpath}}
            The variable $vname could not be found in a local context matching
            $rpath (either that local context doesn't exist or doesn't set that
            variable), inserting an empty string instead.
            """
        return ""
    end
end


"""
    {{insert p base}}

Insert a file at `path(base)/p`. By default `base=path(:layout)` and so paths
can be expressed relative to that or one can pass one of the other path names
such as `folder`, `css`, `libs` or whatever (see `set_paths!`).

The inserted element is resolved in the current active context. Usually it
will be a local context except if the insert is called from within an original
non-layout '.html' file in which case the context is the global one.
"""
function hfun_insert(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true
        )::String

    c = _hfun_check_nargs(:insert, p; kmin=1, kmax=2)
    isempty(c) || return c

    np = length(p)
    np == 1 && return _hfun_insert(lc, p[1], path(:layout); tohtml)
    bsym = Symbol(p[2])
    base = path(bsym)
    return _hfun_insert(lc, p[1], base; bsym, tohtml)
end
hfun_include(a...; kw...) = hfun_insert(a...; kw...)


function _hfun_insert(
            lc::LocalContext,
            p::String,
            base::String;
            bsym::Symbol=:layout,
            tohtml::Bool=true
        )

    if isempty(base)
        @warn """
            {{insert $p $bsym}}
            There's no base path corresponding to '$bsym'.
            """
        return hfun_failed(["insert", p, string(bsym)])
    end

    fpath = base / p
    if !isfile(fpath)
        @warn """
            {{insert $p $bsym}}
            Couldn't find a file '$p' in the folder '$bsym'.
            """
        return hfun_failed(["insert", p, string(bsym)])
    end

    if tohtml && endswith(p, ".html")
        return html2(read(fpath, String), lc)

    elseif endswith(p, ".md")
        @warn """
            {{insert $p $bsym}}
            Insertion of a markdown file is not yet supported.
            """
        return hfun_failed(["insert", p, string(bsym)])
    end
    # for anything else, just dump the file as is
    # (and it's on the user to check that's fine)
    return read(fpath, String)
end


function hfun_page_content(
            lc::LocalContext;
            tohtml::Bool=true
        )::String

    return html2(getvar(lc, :_generated_body), lc)
end
