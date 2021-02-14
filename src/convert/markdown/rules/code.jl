html_code_inline(b::Block, _)  = "<code>$(content(b))</code>"
latex_code_inline(b::Block, _) = "\\texttt{$(replace(content(b), "\\" => "{\\textbackslash}"))}"
