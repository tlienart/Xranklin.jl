html_code_inline(b::Block, _)  = "<code>$(content(b))</code>"
latex_code_inline(b::Block, _) = "\\texttt{$(content(b))}"
