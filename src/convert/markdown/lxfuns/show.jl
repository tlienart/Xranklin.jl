"""
    \\show{cell_name}

Show representation of the cell output + value in a plaintext code block.
"""
function lx_show(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true
        )::String

    c = _lx_check_nargs(:show, p, 1)
    isempty(c) || return c
    # ------------------------------
    case = ifelse(tohtml, :html, :latex)
    return _resolve_show(
                lc, "show", p, case
            )
end


"""
    \\mdshow{cell_name}

Show string of cell output re-interpreting it as markdown.
"""
function lx_mdshow(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true
         )::String

    c = _lx_check_nargs(:show, p, 1)
    isempty(c) || return c
    # ------------------------------
    case = ifelse(tohtml, :rhtml, :rlatex)
    return _resolve_show(
                lc, "mdshow", p, case
            )
end


"""
    \\htmlshow{cell_name}

Show string of cell output as raw HTML.
"""
function lx_htmlshow(
            lc::LocalContext,
            p::VS;
            tohtml::Bool=true
        )::String

    c = _lx_check_nargs(:show, p, 1)
    isempty(c) || return c
    # ------------------------------
    return _resolve_show(
                lc, "htmlshow", p, :raw
            )
end



"""
    _resolve_show(command, p; case)

Helper function for `\\show`, `\\mdshow`, and `\\htmlshow`.
"""
function _resolve_show(
            lc::LocalContext,
            command::String,
            p::VS,
            case::Symbol=:html
        )::String

    # recover the code_pair representation
    nb   = lc.nb_code
    name = strip(p[1])
    idx  = findfirst(==(name), nb.code_names)
    if idx === nothing
        if !env(:nocode)
            @warn """
                \\$command{$name}
                No cell found with name '$name'.
                """
            return failed_lxc("show", p)
        else
            return html_div("""
                       ⚠ No Code Mode, no cached code representation found ⚠.
                       """,
                       class="code-output"
                   )
        end
    end
    id = idx::Int
    re = nb.code_pairs[id].repr
    # different cases of what to do with the representation
    if case == :html
        isempty(re.html) && return ""
        return html_div(re.html, class="code-output")

    elseif case == :latex
        return re.latex

    elseif case == :rhtml
        io = IOBuffer()
        println(io, re.raw)
        return rhtml(String(take!(io)), lc)

    elseif case == :raw
        return re.raw

    end

    return rlatex(re.raw, lc)
end
