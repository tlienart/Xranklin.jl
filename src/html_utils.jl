"""
    attr(name, val)

Convenience function to add an attribute to an html element.
"""
attr(name::Symbol, val::String) = ifelse(isempty(val), "", "$name=\"$val\"")
attr(p::Pair{Symbol,String})    = attr(p.first, p.second)
attr(; kw...)                   = join((attr(p) for p in kw), " ")

"""<a href=..."""
html_a(text::String=""; href::String="", id::String="", class::String="") =
    """<a $(attr(; href, id, class))>$text</a>"""

"""<div class=..."""
html_div(content::String=""; id::String="", class::String="") =
    """<div $(attr(; id, class))>$content</div>"""

"""<img src=..."""
html_img(src::String=""; alt::String="", class::String="") =
    """<img $(attr(; src, alt, class))>"""
