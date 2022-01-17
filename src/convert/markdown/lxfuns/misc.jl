"""
    \\nonumber{display_equation}

Suppress the numbering of that equation.
"""
function lx_nonumber(p::VS; tohtml::Bool=true)::String
    c = _lx_check_nargs(:nonumber, p, 1)
    isempty(c) || return c
    tohtml     || return p[1]
    ctx = cur_lc()
    eqrefs(ctx)["__cntr__"] -= 2
    return "<div class=\"nonumber\">" *
            rhtml(p[1], ctx; nop=true) *
           "</div>"
end
