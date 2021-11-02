#
# FAIL
#
html_failed(s::String)  = html_prepost("[FAILED:]&gt;$s&lt;", "<span>";
                                       style="color:red;")
latex_failed(s::String) = latex_prepost(">$(b.ss)<", "textcolor{crimson}")

html_failed(b, _)  = html_failed(string(b.ss))
latex_failed(b, _) = latex_failed(string(b.ss))


#
# INLINE
#

# plain text
html_text(b, _)  = FP.prepare_text(b)
latex_text(b, _) = FP.prepare_text(b; tohtml=false)

# emphasis
html_emph_em(b, c)         = html_prepost(rhtml(b, c; nop=true), "<em>")
html_emph_strong(b, c)     = html_prepost(rhtml(b, c; nop=true), "<strong>")
html_emph_em_strong(b, c)  = html_prepost(rhtml(b, c; nop=true), "<em><strong>")
latex_emph_em(b, c)        = latex_prepost(rlatex(b, c; nop=true), "textit")
latex_emph_strong(b, c)    = latex_prepost(rlatex(b, c; nop=true), "textbf")
latex_emph_em_strong(b, c) = "\\textbf{\\textit{" * rlatex(b, c; nop=true) * "}}"

# hard line breaks \\
html_linebreak(b, _)  = "\n<br>\n"
latex_linebreak(b, _) = "\\\\"

#  ???...???
html_raw(b, _)  = content(b)
latex_raw(b, _) = content(b)

#  ~~~...~~~
html_raw_html(b, _)  = content(b)
latex_raw_html(b, _) = ""

#  %%%...%%%
html_raw_latex(b, _)  = ""
latex_raw_latex(b, _) = content(b)

# {{...}}
html_dbb(b, _)  = string(b.ss)  # will be post-processed in html2
latex_dbb(b, _) = string(b.ss)  # will be post-processed in latex2

#
# BLOCK (not inline)
#

# ---
html_hrule(b, _)  = "\n<hr>\n"
latex_hrule(b, _) = raw"\par\noindent\rule{\textwidth}{0.1pt}\par"

# @@...@@
html_div(b, c)  = html_prepost(rhtml(b, c), "<div>"; class=FP.get_classes(b))
latex_div(b, c) = rlatex(b, c)

# >
html_blockquote(b, c)  = html_prepost(rhtml(b, c), "<blockquote>")
latex_blockquote(b, c) = "\\begin{displayquote}" * rlatex(b, c) * "\\end{displayquote}"

#
# PAGE VAR CODE
#

html_md_def(b, c)  = (eval_vars_cell!(c, content(b)); "")
latex_md_def(b, c) = (eval_vars_cell!(c, content(b)); "")
html_md_def_block  = html_md_def
latex_md_def_block = latex_md_def
