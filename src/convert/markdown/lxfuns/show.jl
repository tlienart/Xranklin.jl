
"""
    \\show{cell_name}

Show representation of the cell output + value in a plaintext code block.
"""
function lx_show(p::VS; tohtml::Bool=true)::String
    c = _lx_check_nargs(:show, p, 1)
    isempty(c) || return c

    tohtml || throw("Not Implemented")

    # XXX (need to check whether exists)
    ctx = cur_lc()
    nb  = ctx.nb_code
    id  = nb.code_map[p[1]]
    re  = ifelse(tohtml, nb.code_pairs[id].repr.html, nb.code_pairs[id].repr.latex)
    isempty(re) && return ""
    return """<div class="code-output">""" * re * "</div>"
end
