
"""
    \\show{cell_name}

Show representation of the cell output + value in a plaintext code block.
"""
function lx_show(p::VS; tohtml::Bool=true)::String
    c = _lx_check_nargs(:show, p, 1)
    isempty(c) || return c
    ctx = cur_lc()
    nb  = ctx.nb_code
    if p[1] in keys(nb.code_map)
        id  = nb.code_map[p[1]]
        re  = ifelse(tohtml,
            nb.code_pairs[id].repr.html,
            nb.code_pairs[id].repr.latex
        )

        isempty(re) && return ""
        tohtml && return """<div class="code-output">""" * re * "</div>"
        return re
    end
    return lx_failed("show", p)
end
