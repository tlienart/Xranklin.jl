
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

"""
    _hide_lines(c)
"""
function _hide_lines(c)::SS
    io = IOBuffer()
    for line in split(c, '\n')
        m  = match(CODE_HIDE_PAT, line)
        ml = match(LITERATE_HIDE_PAT, line)
        if m === ml === nothing
            println(io, replace(line, CODE_MOCK_PAT => ""))
        elseif m !== nothing && m.captures[2] !== nothing
            # case 'hideall'
            return subs("")
        end
    end
    return strip(String(take!(io)))
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
# entry points: html_code_block / latex_code_block
# overview:
#   - _code_info() --> CodeInfo {name, lang, code, exec, auto}
#                       (auto name attributed here if relevant)
#   - if exec
#       => call eval_code_cell!(...)
#   - if auto
#       => call lx_show(...)
#   - ...
#
# eval_code_cell!(...)
#   - unchanged code at the cell counter
#       >
#

"""
    _strip(s)

Strip `s` from spaces that are not whitespaces (usually line returns).
"""
_strip(s) = strip(c -> (c != ' ') && isspace(c), s)


"""
    CodeInfo

Object to keep track of code and information passed around it (e.g. is it an
executable code cell, should we force re-execute it, is it independent from
other cells etc).
"""
struct CodeInfo
    name::String
    lang::String
    code::SS
    exec::Bool
    auto::Bool
    force::Bool
    indep::Bool
end
function CodeInfo(;
            name="",
            lang="",
            code=subs(""),
            exec=false,
            auto=false,
            force=false,
            indep=false
        )
    CodeInfo(name, lang, code, exec, auto, force, indep)
end


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

If the "!" or ":" is doubled (i.e. "!!" or "::") the cell will be evaluated
in all scenarios. This can be useful for debugging or force-refreshing a
cell but should otherwise not be used.
"""
function _code_info(
            b::Block,
            ctx::LocalContext
        )::CodeInfo

    info = match(CODE_INFO_PAT, b.ss).captures[1]
    lang = getvar(ctx, :lang, "")
    info === nothing && return CodeInfo(; lang, code=_strip(content(b)))

    info = string(info)
    cb   = content(b)
    code = subs(cb, nextind(cb, lastindex(info)), lastindex(cb)) |> _strip

    name  = ""
    exec  = false
    auto  = false
    force = false
    indep = false

    l, e, n = match(CODE_LANG_PAT, info)

    if !isnothing(l)
        lang = l
    end
    if !isnothing(e)
        exec = true
    end

    if exec
        # Either attribute a name to the code automatically based on when
        # it appears on the page, or - if a name hint is given - use the
        # name hint.
        if !isnothing(n)
            name = n
        else
            name_hint = ""
            m = match(AUTO_NAME_HINT_PAT, code)
            if !isnothing(m)
                name_hint = m.captures[1]
                code = replace(code, AUTO_NAME_HINT_PAT => "\n")
            end

            name  = auto_cell_name(ctx)
            name *= ifelse(isempty(name_hint), "", " ($name_hint)")
            auto  = true
        end
        # If there's a doubling of `!` or `:` then the cell should
        # be force re-executed.
        if length(e) == 2
            force = true
        end
        # If there's an '# indep ' on a line, then mark the code
        # as indep
        m = match(CODE_INDEP_PAT, code)
        if !isnothing(m)
            indep = true
            code  = replace(code, CODE_INDEP_PAT => "\n")
        end
    end

    return CodeInfo(; name, lang, code=strip(code, ['\n']), exec, auto, force, indep)
end


"""
    auto_cell_name(ctx)

Assign a name to a code cell based on the notebook counter (and increment
the notebook counter).
"""
function auto_cell_name(
            ctx::LocalContext
        )::String

    cntr  = getvar(ctx, :_auto_cell_counter, 0)
    cntr += 1
    setvar!(ctx, :_auto_cell_counter, cntr)
    cell_name = "auto_cell_$cntr"
    return cell_name
end

auto_cell_name() = auto_cell_name(cur_lc())


"""
    html_code_block(b, c)

Represent a code block `b` as HTML in the local context `c`.
"""
function html_code_block(
            b::Block,
            c::LocalContext
        )::String

    hascode!(c)
    ci   = _code_info(b, c)
    # placeholder for output string if has to be added directly after code
    # might remain empty if result is nothing or if it's not an auto-cell
    post = ""
    if ci.exec
        if ci.lang == "julia"
            imgdir_base  = mkpath(path(:site) / "assets" / noext(c.rpath))
            imgdir_html  = mkpath(imgdir_base / "figs-html")
            imgdir_latex = mkpath(imgdir_base / "figs-latex")
            eval_code_cell!(
                c, ci.code, ci.name;
                imgdir_html, imgdir_latex, force=ci.force, indep=ci.indep
            )
        end
        if ci.auto
            post = lx_show([ci.name])
        end
        code = ci.code |> _hide_lines |> _hescape
    else
        code = ci.code |> _hescape
    end
    return ifelse(isempty(code), "", """
        <pre><code class=\"$(ci.lang)\">$code</code></pre>
        """) * post
end


"""
    latex_code_block(b, c)

Represent a code block `b` as LaTeX in the local context `c`.
"""
function latex_code_block(
            b::Block,
            c::LocalContext
        )::String

    ci = _code_info(b, c)
    if ci.exec
        if ci.lang == "julia"
            eval_code_cell!(c, ci.code, ci.name; force=ci.force)
        end
        if ci.auto
            post = lx_show([ci.name]; tohtml=false)
        end
        code = ci.code |> _hide_lines |> _hescape
    else
        code = ci.code |> _hescape
    end
    return ifelse(isempty(code), "", """
        \\begin{lstlisting}\n$code\n\\end{lstlisting}
        """) * post
end
