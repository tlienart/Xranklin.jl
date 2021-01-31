html_text(b::Block, ::Context)  = FP.prepare_text(b) |> md2html
latex_text(b::Block, ::Context) = FP.prepare_text(b) |> md2latex

html_comment(b::Block,  ::Context) = ""
latex_comment(b::Block, ::Context) = ""

html_linebreak(b::Block, ::Context)  = "<br>"
latex_linebreak(b::Block, ::Context) = raw"\\"

html_hrule(b::Block,  ::Context) = "<hr>"
latex_hrule(b::Block, ::Context) = raw"\par\noindent\rule{\textwidth}{0.1pt}"

html_raw_html(b::Block,  ::Context) = content(b)
latex_raw_html(b::Block, ::Context) = ""

html_code_inline(b::Block, ::Context) = "<code>$(content(b))</code>"


html_div(b::Block, c::Context) =
    """<div class="$(FP.get_classes(b))">$(html(content(b), c))</div>"""

latex_div(b::Block, c::Context) = latex(content(b), c)
