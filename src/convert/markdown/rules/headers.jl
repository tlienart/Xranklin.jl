html_h1(b, c) = html_hk(b, c, :h1)
html_h2(b, c) = html_hk(b, c, :h2)
html_h3(b, c) = html_hk(b, c, :h3)
html_h4(b, c) = html_hk(b, c, :h4)
html_h5(b, c) = html_hk(b, c, :h5)
html_h6(b, c) = html_hk(b, c, :h6)

latex_h1(b, c) = latex_hk(b, c, :h1)
latex_h2(b, c) = latex_hk(b, c, :h2)
latex_h3(b, c) = latex_hk(b, c, :h3)
latex_h4(b, c) = latex_hk(b, c, :h4)
latex_h5(b, c) = latex_hk(b, c, :h5)
latex_h6(b, c) = latex_hk(b, c, :h6)

function html_hk(b, c, hk::Symbol)
    header_text = recursive_html(b, c)
    # strip <p> / </p>
    header_text = replace(header_text, r"(?:^\s*<p>\s*)|(?:</p>\s*$)" => "")
    # header id
    id = header_id(c, header_text, hk)
    # extra attributes
    class      = value(c, :header_class)
    add_link   = value(c, :header_link)
    link_class = value(c, :header_link_class)
    # make the header a link if required
    if add_link
        header_text = "<a href=\"#$(id)\">$(header_text)</a>"
    end
    return "<$(hk)$(attr(:id, id))$(attr(:class, class))>" *
           "$header_text" *
           "</$hk>"
end

function latex_hk(b, c, hk::Symbol)
    header_text = recursive_latex(b, c)
    # strip \\par
    header_text = replace(header_text, r"(?:\\par\s*$)" => "")
    id = header_id(c, header_text, hk)
    hk in (:h4, :h5, :h6) && return header_text
    hk == :h1 && return "\\section{\\label{$id}$header_text}"
    hk == :h2 && return "\\subsection{\\label{$id}$header_text}"
    return "\\subsubsection{\\label{$id}$header_text}"
end

function header_id(c::Context, header_text::String, hk::Symbol)::String
    id  = string_to_anchor(header_text)
    lvl = parse(Int, String(hk)[2])
    if id in keys(c.headers)
        n, ex_lvl = c.headers[id]
        # keep track of occurrence number
        c.headers[id] = (n+1, ex_lvl)
        # update the refstring, note the double '_'
        id *= "__$(n+1)"
        # add a new entry to keep track of that header
        c.headers[id] = (1, lvl)
    else
        c.headers[id] = (1, lvl)
    end
    return id
end
