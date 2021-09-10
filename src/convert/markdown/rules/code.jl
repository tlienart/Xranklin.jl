function _hescape(s)
    s = escape_xml(s)
    for p in ("{" => "&lbrace;", "}" => "&rbrace;")
        s = replace(s, p)
    end
    return s
end

function _lescape(s)
    for p in ("\\" => "{\\textbackslash}", r"({|})" => s"\\\1")
        s = replace(s, p)
    end
    return s
end

#
# INLINE
#


html_code_inline(b::Block, _)  = "<code>" *
                                 (b |> content |> _hescape) *
                                 "</code>"

latex_code_inline(b::Block, _) = "\\texttt{" *
                                 (b |> content |> _lescape) *
                                 "}"

#
# TODO: eval code if known language etc.
#

_isspace2(c) = (c != ' ') && isspace(c)
_strip(s)    = strip(_isspace2, s)
_lang(b)     = lstrip(b.open.ss, '`')


html_code_block(b::Block, _) =
    "<pre><code class=\"plaintext\">" *
      (b |> content |> _strip |> _hescape ) *
    "</code></pre>"

html_code_block_lang(b::Block, _) =
    "<pre><code class=\"$(_lang(b))\">" *
      (b |> content |> _strip |> _hescape) *
    "</code></pre>"

latex_code_block(b::Block, _) =
    "\\begin{lstlisting}\n" *
      (b |> content |> _strip |> _lescape) *
    "\\end{lstlisting}"

latex_code_block_lang(b::Block, _) =
    "\\begin{lstlisting}[language=$(_lang(b))]\n" *
      (b |> content |> _strip |> _lescape) *
    "\\end{lstlisting}"
