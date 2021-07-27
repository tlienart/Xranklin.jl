html_code_inline(b::Block, _)  = "<code>" *
                                 content(b) *
                                 "</code>"

latex_code_inline(b::Block, _) = "\\texttt{" *
                                 (replace(content(b), "\\" => "{\\textbackslash}")) *
                                 "}"

#
# TODO: eval code if known language etc.
#

_isspace2(c) = (c != ' ') && isspace(c)
_strip(s)    = strip(_isspace2, s)
_lang(b)     = lstrip(b.open.ss, '`')


html_code_block(b::Block, _)       = "<pre><code class=\"plaintext\">" *
                                     (b |> content |> _strip |> escape_xml) *
                                     "</code></pre>"

latex_code_block(b::Block, _)      = "\\begin{lstlisting}\n" *
                                     (b |> content |> _strip) *
                                     "\\end{lstlisting}"

html_code_block_lang(b::Block, _)  = "<pre><code class=\"$(_lang(b))\">" *
                                     (b |> content |> strip |> escape_xml) *
                                     "</code></pre>"

latex_code_block_lang(b::Block, _) = "\\begin{lstlisting}[language=$(_lang(b))]\n" *
                                     (b |> content |> _strip) *
                                     "\\end{lstlisting}"
