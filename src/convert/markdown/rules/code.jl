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

# ============================================================================
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

# ============================================================================
#
# BLOCK
#

"""
    _strip(s)

Strip `s` from spaces that are not whitespaces (usually line returns).
"""
_strip(s) = strip(c -> (c != ' ') && isspace(c), s)

struct CodeInfo
    name::String
    lang::String
    code::SS
    exec::Bool
    auto::Bool
end
CodeInfo(; name="", lang="", code=subs(""), exec=false, auto=false) =
    CodeInfo(name, lang, code, exec, auto)

"""
    _code_info(b)

Extract the language, name, code and an execution flag for a code block.
The different cases are:

*                    - non-executed, un-named, implicit language
* lang               - non-executed, un-named, explicit language
* !       | :        - executed, auto-named, implicit language
* !ex     | :ex      - executed, named, implicit language
* lang!   | lang:    - executed, auto-named, explicit language
* lang!ex | lang:ex  - executed, named, explicit language (with colon is for legacy)

Return a CodeInfo.
"""
function _code_info(b::Block, ctx::LocalContext)
    info = match(CODE_INFO_PAT, b.ss).captures[1]
    lang = getvar(ctx, :lang, "")
    info === nothing && return CodeInfo(; lang, code=_strip(content(b)))

    info = string(info)
    cb   = content(b)
    code = subs(cb, nextind(cb, lastindex(info)), lastindex(cb)) |> _strip

    name = ""
    exec = false
    auto = false

    l, e, n = match(CODE_LANG_PAT, info)

    if !isnothing(l)
        lang = l
    end
    if !isnothing(e)
        exec = true
    end
    if exec
        if !isnothing(n)
            name = n
        else
            name = _auto_cell_name(ctx)
            auto = true
        end
    end
    return CodeInfo(; name, lang, code, exec, auto)
end

"""
    _auto_cell_name(ctx)

Assign a name to a code cell based on the notebook counter (and increment
the notebook counter).
"""
function _auto_cell_name(ctx::LocalContext)
    cntr  = getvar(ctx, :_auto_cell_counter, 0)
    cntr += 1
    setvar!(ctx, :_auto_cell_counter, cntr)
    cell_name = "auto_cell_$cntr"
    return cell_name
end


html_code_block(b::Block, c::LocalContext) = begin
    hascode!(c)
    ci   = _code_info(b, c)
    post = ""
    if ci.exec
        if ci.lang == "julia"
            imgdir_base  = mkpath(path(:site) / "assets" / splitext(c.rpath)[1])
            imgdir_html  = mkpath(imgdir_base / "figs-html")
            imgdir_latex = mkpath(imgdir_base / "figs-latex")
            eval_code_cell!(
                c, ci.code;
                cell_name=ci.name,
                imgdir_html,
                imgdir_latex
            )
        end
        if ci.auto
            post = lx_show([ci.name])
        end
    end

    return "<pre><code class=\"$(ci.lang)\">"  *
             (ci.code |> _hescape ) *
           "</code></pre>" * post
end

latex_code_block(b::Block, c::LocalContext) = begin
    ci = _code_info(b, c)
    if ci.exec
        if ci.lang == "julia"
            eval_code_cell!(c, ci.code; cell_name=ci.name)
        end
        if ci.auto
            post = lx_show([ci.name]; tohtml=false)
        end
    end
    return "\\begin{lstlisting}\n" *
             (ci.code |> _lescape) *
           "\\end{lstlisting}" * post
end
