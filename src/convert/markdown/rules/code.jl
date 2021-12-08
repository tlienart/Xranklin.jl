"""
    _hescape(s)

Helper function to escape a code string `s` before displaying it in HTML.
"""
function _hescape(s)
    s = escape_xml(s)
    for p in ("{" => "&lbrace;", "}" => "&rbrace;")
        s = replace(s, p)
    end
    return s
end

"""
    _lescape(s)

Helper function to escape a code string `s` before displaying it in LaTeX.
"""
function _lescape(s)
    for p in ("\\" => "{\\textbackslash}", r"({|})" => s"\\\1")
        s = replace(s, p)
    end
    return s
end


#
# INLINE, not executed
#

html_code_inline(b::Block, c::LocalContext) = (
    hascode!(c);
    "<code>" * (b |> content |> strip |> _hescape) * "</code>"
)

latex_code_inline(b::Block, c::LocalContext) = (
    hascode!(c);
    "\\texttt{" * (b |> content |> strip |> _lescape) * "}"
)

#
# BLOCK, not executed
#

_isspace2(c) = (c != ' ') && isspace(c)
_strip(s)    = strip(_isspace2, s)
_lang(b)     = lstrip(b.open.ss, '`') |> lowercase

function _cell_name_code(b)::Pair{String, SS}
    c = content(b)
    startswith(c, ":") || return ("" => c)
    # first whitespace after lang(:name)?
    w = findfirst(r"\s", c)
    isnothing(w) && return ("" => c)  # should not happen, malformed cell
    w = first(w)::Int
    cell_name = subs(c, 2, prevind(c, w)) |> string
    code      = subs(c, nextind(c, w), lastindex(c))
    return (cell_name => code)
end


html_code_block(b::Block, c::LocalContext) = (
    hascode!(c);
    "<pre><code class=\"plaintext\">" *
      (b |> content |> _strip |> _hescape ) *
    "</code></pre>"
)

latex_code_block(b::Block, c::LocalContext) = (
    hascode!(c);
    "\\begin{lstlisting}\n" *
      (b |> content |> _strip |> _lescape) *
    "\\end{lstlisting}"
)

#
# BLOCK, not executed unless language is known
# -> Julia (native)
# -> XXX Python (via PyCall in some dedicated environment?)
# -> XXX R (via RCall)
#

html_code_block_lang(b::Block, ctx::LocalContext; lang=_lang(b), auto_name=false) = begin
    hascode!(ctx)
    cell_name, code = _cell_name_code(b)
    if !isempty(cell_name) || auto_name
        if lang == "julia"
            eval_julia_code(code, ctx; cell_name)
        end
    end
    "<pre><code class=\"$lang\">" *
      (code |> _strip |> _hescape) *
    "</code></pre>"
end

latex_code_block_lang(b::Block, _) = begin
    # XXX see  above
    hascode!(c)
    lang = _lang(b)
    "\\begin{lstlisting}[language=$lang]\n" *
      (b |> content |> _strip |> _lescape) *
    "\\end{lstlisting}"
end

#
# BLOCK, auto executed if locvar(:lang) is known
#

html_code_block!(b::Block, ctx::LocalContext) = begin
    html_code = html_code_block_lang(
        b, ctx;
        lang=getvar(ctx, :lang), auto_name=true
        )
    html_out  = ""
    #
    # XXX should be given by previous stuff
    cntr      = getvar(ctx, :_auto_cell_counter, 1)
    cell_name = "auto_cell_$cntr"
    # XXX
    if getvar(ctx, :showall, true)
        html_out = lx_show([cell_name])
    end
    return html_code * html_out
end

latex_code_block!(b::Block, ctx::LocalContext) = begin
end

# XXX
# Name splitting must happen within some more elaborate  _lang otherwise
# the name gets shown which is dumb

# ----

function auto_cell_name(ctx)
    cntr = getvar(ctx, :_auto_cell_counter, 1)
    cntr += 1
    setvar!(ctx, :_auto_cell_counter, cntr)
    cell_name = "auto_cell_$cntr"
    return cell_name
end

function eval_julia_code(
            code::SubString, ctx::LocalContext;
            cell_name::String=""
        )
    if isempty(cell_name)
        cell_name = auto_cell_name(ctx)
    end
    # ----------------------------------
    # XXX autofig stuffs (see eval_code)
    # ----------------------------------
    eval_code_cell!(
        ctx, code;
        cell_name
        # imgdir_html / imgdir_latex
    )
    return
end
