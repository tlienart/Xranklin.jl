# plain text
html_text(b, _)        = FP.prepare_text(b) |> md2html
latex_text(b, _)       = FP.prepare_text(b) |> md2latex

# \\
html_linebreak(b, _)   = "<br>"
latex_linebreak(b, _)  = "\\\\"

# ---
html_hrule(b, _)       = "<hr>"
latex_hrule(b, _)      = raw"\par\noindent\rule{\textwidth}{0.1pt}\par"

# ~~~...~~~
html_raw_html(b, _)    = content(b)
latex_raw_html(b, _)   = ""

# @@...@@
html_div(b, c)         = "<div class=\"$(FP.get_classes(b))\">" *
                            recursive_html(b, c) *
                         "</div>"
latex_div(b, c)        = recursive_latex(b, c)

# {{...}}
html_dbb(b, _)         = string(b.ss)  # will be post-processed in html2
latex_dbb(b, _)        = string(b.ss)  # will be post-processed in latex2

# failed blocks
html_failed(s::String)  = "<span style=\"color:red\">[FAILED:]&gt;$s&lt;</span>"
latex_failed(s::String) = "\\textcolor{crimson}{>$(b.ss)<}"
html_failed(b, _)       = html_failed(string(b.ss))
latex_failed(b, _)      = latex_failed(string(b.ss))

# Markdown defs
html_md_def(b, c)  = (eval_vars_cell!(c, content(b)); "")
latex_md_def(b, c) = (eval_vars_cell!(c, content(b)); "")
html_md_def_block  = html_md_def
latex_md_def_block = latex_md_def
