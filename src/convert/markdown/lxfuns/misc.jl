"""
    \\par{paragraph}

Force the content of the command to be treated as a paragraph.
"""
function lx_par(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true
        )::String

    c = _lx_check_nargs(:par, p, 1)
    isempty(c) || return c
    # -----------------------------
    tohtml && return rhtml(p[1], lc; nop=false)
    return rlatex(p[1], lc; nop=false)
end

"""
    \\nonumber{display_equation}

Suppress the numbering of that equation.
"""
function lx_nonumber(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true
        )::String

    c = _lx_check_nargs(:nonumber, p, 1)
    isempty(c) || return c
    # ----------------------------------
    tohtml || return p[1]
    eqrefs(lc)["__cntr__"] -= 2
    return "<div class=\"nonumber\">" *
            rhtml(p[1], lc; nop=true) *
           "</div>"
end
