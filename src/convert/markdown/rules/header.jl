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

"""
    html_hk(b, c; hk)

Process a block corresponding to a heading of level `hk` and convert it to
HTML.
"""
function html_hk(b::Block, c::LocalContext, hk::Symbol)
    heading_text = rhtml(b, c; nop=true)
    id           = heading_id(c, heading_text, hk)
    # extra attributes
    class       = getvar(c, :heading_class)::String
    add_link    = getvar(c, :heading_link)::Bool
    link_class  = getvar(c, :heading_link_class)::String
    post        = getvar(c, :heading_post)::String
    # make the heading a link if required
    if add_link
        heading_text = "<a href=\"#$(id)\">$(heading_text)</a>"
    end
    return "<$(hk) $(attr(:id, id)) $(attr(:class, class))>" *
             heading_text *
             replace(post, "HEADING_ID" => id) *
           "</$hk>"
end


"""
    latex_hk(b, c; hk)

Process a block corresponding to a heading of level `hk` and convert it to
LaTeX.

## Note

Level 4-5-6 are not supported in LaTeX and so will just be written as text.
"""
function latex_hk(b::Block, c::LocalContext, hk::Symbol)
    heading_text = rlatex(b, c; nop=true)
    id           = heading_id(c, heading_text, hk)
    hk in (:h4, :h5, :h6) && return heading_text
    hk == :h1 && return "\\section{\\label{$id}$heading_text}"
    hk == :h2 && return "\\subsection{\\label{$id}$heading_text}"
    return "\\subsubsection{\\label{$id}$heading_text}"
end


"""
    heading_id(c, heading_text, hk)

Return a processed version of `heading_text` which can identify the heading
(id) and add an entry in the context's headings.
Also add it to the global set of anchors (see `lx_reflink`).
"""
function heading_id(c::LocalContext, heading_text::String, hk::Symbol)::String
    id  = string_to_anchor(heading_text)
    lvl = parse(Int, String(hk)[2])
    if id in keys(c.headings)
        # keep track of occurrence number for the original id
        n, l, t = c.headings[id]
        c.headings[id] = (n+1, l, t)
        id = "$(id)__$(n+1)"
    end
    # add the heading to the local context set of headings
    c.headings[id] = (1, lvl, heading_text)
    # add the anchor to the global context set of anchors
    # note that this can overwrite an existing anchor
    add_anchor(c.glob, id, c.rpath)
    return id
end
