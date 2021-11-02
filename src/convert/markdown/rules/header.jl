html_h1(b, c)  = html_hk(b, c, :h1)
html_h2(b, c)  = html_hk(b, c, :h2)
html_h3(b, c)  = html_hk(b, c, :h3)
html_h4(b, c)  = html_hk(b, c, :h4)
html_h5(b, c)  = html_hk(b, c, :h5)
html_h6(b, c)  = html_hk(b, c, :h6)

latex_h1(b, c) = latex_hk(b, c, :h1)
latex_h2(b, c) = latex_hk(b, c, :h2)
latex_h3(b, c) = latex_hk(b, c, :h3)
latex_h4(b, c) = latex_hk(b, c, :h4)
latex_h5(b, c) = latex_hk(b, c, :h5)
latex_h6(b, c) = latex_hk(b, c, :h6)

function html_hk(b, c, hk::Symbol)
    header_text = rhtml(b, c)
    # strip <p> / </p>
    header_text = replace(header_text, r"(?:^\s*<p>\s*)|(?:</p>\s*$)" => "")
    # header id
    id = header_id(c, header_text, hk)
    # extra attributes
    class      = getvar(c, :header_class)::String
    add_link   = getvar(c, :header_link)::Bool
    link_class = getvar(c, :header_link_class)::String
    # make the header a link if required
    if add_link
        header_text = "<a href=\"#$(id)\">$(header_text)</a>"
    end
    return "<$(hk) $(attr(:id, id)) $(attr(:class, class))>" *
           header_text *
           "</$hk>"
end

function latex_hk(b, c, hk::Symbol)
    header_text = rlatex(b, c)
    # strip \\par
    header_text = replace(header_text, r"(?:\\par\s*$)" => "")
    id = header_id(c, header_text, hk)
    hk in (:h4, :h5, :h6) && return header_text
    hk == :h1 && return "\\section{\\label{$id}$header_text}"
    hk == :h2 && return "\\subsection{\\label{$id}$header_text}"
    return "\\subsubsection{\\label{$id}$header_text}"
end

"""
    header_id(c, header_text, hk)

Return a processed version of `header_text` which can identify the header (id)
and add an entry in the context's headers.
"""
function header_id(c::LocalContext, header_text::String, hk::Symbol)::String
    id  = string_to_anchor(header_text)
    lvl = parse(Int, String(hk)[2])
    if id in keys(c.headers)
        # keep track of occurrence number for the original id
        n, l, t = c.headers[id]
        c.headers[id] = (n+1, l, t)
        # create a derived refstring + entry, note the double '_'
        c.headers["$(id)__$(n+1)"] = (1, lvl, header_text)
    else
        c.headers[id] = (1, lvl, header_text)
    end
    return id
end