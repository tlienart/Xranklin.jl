# ---------------------------------------------------
# NOTE
# hfun must necessarily return a String; see outputof
# hfun can *optionally* take one specific keyword
# tohtml=(true|false). If a hfun doesn't have that
# keyword then its output will be used in all cases;
# If it does have the keyword, then it may behave
# differently when the requested output is html or
# latex.
# ---------------------------------------------------

const INTERNAL_HENVS = [
    # :if,
    # :ifdef, :isdef,
    # :ifndef, :ifnotdef, :isndef, :isnotdef,
    # :ifempty, :isempty,
    # :ifnempty, :ifnotempty, :isnotempty,
    # :ispage, :ifpage,
    # :isnotpage, :ifnotpage,
    # :for
]

const INTERNAL_HFUNS = [
    :failed,
    :fill,
    :insert, # :include
    # ...
]


"""
    {{failed ...}}

Hfun used for when other hfuns fail.
"""
function hfun_failed(p::VS; tohtml::Bool=true)::String
    tohtml && return _hfun_failed_html(p)
    return _hfun_failed_latex(p)
end
hfun_failed(s::String, p::VS) = hfun_failed([s, p...])

_hfun_failed_html(p::VS) = html_failed(
    "&lbrace;&lbrace; " * prod(e * " " for e in p) * "&rbrace;&rbrace;"
)
_hfun_failed_latex(p::VS) = latex_failed(
    s = raw"\texttt{\{\{ " * prod(e * " " for e in p) * raw"\}\}}"
)


"""
    {{fill x}}
    {{fill x from}}

Write the value of variable `x` from either the local context or the context
of the page at `from`.
"""
function hfun_fill(p::VS)::String
    # check parameters
    np = length(p)
    if np ∉ [1, 2]
        @warn """
            {{fill ...}}
            ------------
            Fill should get one or two parameters, $np given.
            """
        return hfun_failed("fill", p)
    end
    out = (np == 1) ? _hfun_fill_1(p) : _hfun_fill_2(p)
    return out
end

function _hfun_fill_1(p::VS)::String
    vname = Symbol(p[1])
    if (v = getvar(cur_lc(), vname)) !== nothing
        return string(v)
    elseif vname in utils_var_names()
        mdl = cur_gc().nb_code.mdl
        return string(getproperty(mdl, vname))
    else
        @warn """
            {{fill $vname}}
            ---------------
            The variable $vname does not match a variable in the context,
            inserting an empty string instead.
            """
        return ""
    end
end

function _hfun_fill_2(p::VS)::String
    vname = Symbol(p[1])
    rpath = strip(p[2], '/')
    endswith(rpath, ".md") || (rpath *= ".md")
    gc = cur_gc()
    has_var = rpath in keys(gc.children_contexts) &&
              vname in keys(gc.children_contexts[rpath].vars)
    if has_var
        return string(gc.children_contexts[rpath].vars[vname])
    else
        @warn """
            {{fill $vname $rpath}}
            ----------------------
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
"""
function hfun_insert(p::VS; tohtml::Bool=true)::String
    np = length(p)
    if np ∉ [1, 2]
        @warn """
            {{insert ...}}
            --------------
            Insert should get one or two parameters, $np given.
            """
        return hfun_failed("insert", p)
    end
    np == 1 && return _hfun_insert(p[1], path(:layout); tohtml)
    bsym = Symbol(p[2])
    base = path(bsym)
    return _hfun_insert(p[1], base; bsym, tohtml)
end

function _hfun_insert(p::String, base::String;
                      bsym::Symbol=:layout, tohtml::Bool=true)
    if isempty(base)
        @warn """
            {{insert $p $bsym}}
            -------------------
            There's no base path corresponding to '$bsym'.
            """
        return hfun_failed(["insert", p, string(bsym)])
    end
    fpath = base / p
    if !isfile(fpath)
        @warn """
            {{insert $p $bsym}}
            -------------------
            Couldn't find a file '$p' in the folder '$bsym'.
            """
        return hfun_failed(["insert", p, string(bsym)])
    end
    if tohtml && endswith(p, ".html")
        io = IOBuffer()
        process_html_file_io!(io, cur_gc(), fpath)
        return String(take!(io))
    elseif endswith(p, ".md")
        io = IOBuffer()
        process_md_file_io!(io, cur_gc(), fpath; tohtml)
        return String(take!(io))
    end
    # for anything else, just dump the file as is
    # (and it's on the user to check that's fine)
    return read(fpath, String)
end
