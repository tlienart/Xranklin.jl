"""
    \\show{cell_name}

Show representation of the cell output + value in a plaintext code block.
"""
function lx_show(
            p::VS;
            tohtml::Bool=true,
            lc::Union{Nothing,LocalContext}=nothing
        )::String

    c = _lx_check_nargs(:show, p, 1)
    isempty(c) || return c
    # ------------------------------
    return _resolve_show(
            "show", p;
            case=ifelse(tohtml, :html, :latex),
            lc
    )
end


"""
    \\mdshow{cell_name}

Show string of cell output re-interpreting it as markdown.
"""
function lx_mdshow(p::VS; tohtml::Bool=true)::String
    c = _lx_check_nargs(:show, p, 1)
    isempty(c) || return c
    # ------------------------------
    return _resolve_show("mdshow", p; case=ifelse(tohtml, :rhtml, :rlatex))
end


"""
    \\htmlshow{cell_name}

Show string of cell output as raw HTML.
"""
function lx_htmlshow(p::VS; tohtml::Bool=true)::String
    c = _lx_check_nargs(:show, p, 1)
    isempty(c) || return c
    # ------------------------------
    return _resolve_show("htmlshow", p; case=:raw)
end



"""
    _resolve_show(command, p; case)

Helper function for `\\show` and `\\mdshow`.
"""
function _resolve_show(
        command::String, p::VS;
        case::Symbol=:html,
        lc::Union{Nothing, LocalContext}=nothing
        )::String

    if isnothing(lc)
        ctx = cur_lc()
    else
        ctx = lc
    end

    # recover the code_pair representation
    nb   = ctx.nb_code
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
                """, class="code-output")
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
        return rhtml(String(take!(io)), ctx)

    elseif case == :raw
        return re.raw

    end

    return rlatex(re.raw, ctx)
end
