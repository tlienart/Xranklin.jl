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
    return failed_lxc("show", p)
end

"""
    \\mdshow{cell_name}

Show string of cell output re-interpreting it as markdown.
"""
function lx_mdshow(p::VS; tohtml::Bool=true)::String
    c = _lx_check_nargs(:show, p, 1)
    isempty(c) || return c
    ctx = cur_lc()
    nb  = ctx.nb_code
    if p[1] in keys(nb.code_map)
        id = nb.code_map[p[1]]
        re = nb.code_pairs[id].repr.raw
        isempty(re) && return ""
        tohtml && return rhtml(re, ctx)
        return rlatex(re, ctx)
    end
    return failed_lxc("showmd", p)
end
