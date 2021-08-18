"""
    attr(name, val)

Convenience function to add an attribute to an html element.
"""
attr(name::Symbol, val::String) = ifelse(isempty(val), "", "$name=\"$val\"")


html_a(text=""; href="", id::String="", class::String="") =
    """<a $(attr(:href, href)) $(attr(:id, id)) $(attr(:class, class))>$text</a>"""

html_div(content::String=""; id::String="", class::String="") =
    """<div $(attr(:id, id)) $(attr(:class, class))>$content</div>"""
