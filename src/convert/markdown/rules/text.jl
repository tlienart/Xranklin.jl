html_text(b::Block, _)  = FP.prepare_text(b) |> md2html
latex_text(b::Block, _) = FP.prepare_text(b) |> md2latex

html_comment(b::Block, _)  = ""
latex_comment(b::Block, _) = ""

html_linebreak(b::Block, _)  = "<br>"
latex_linebreak(b::Block, _) = "\\\\"

html_hrule(b::Block, _)  = "<hr>"
latex_hrule(b::Block, _) = raw"\par\noindent\rule{\textwidth}{0.1pt}"

html_raw_html(b::Block, _)  = content(b)
latex_raw_html(b::Block, _) = ""

html_div(b::Block, c::Context)  =
    """<div class="$(FP.get_classes(b))">$(html(content(b), c))</div>"""
latex_div(b::Block, c::Context) = latex(content(b), c)

# html_h1(b::Block, _)
