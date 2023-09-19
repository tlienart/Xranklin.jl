
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
* lang!   | lang:    - executed, auto-named, explicit language (†)
* lang!ex | lang:ex  - executed, named, explicit language (with colon is for
                        legacy) (†)
* > ; ] ?            - executed, auto-named, repl mode (††)
* >ex ;ex ]ex ?ex    - executed, named, julia-repl mode

(†) a whitespace can be inserted after the language and before the execution
symbol to allow for syntax highlighting in markdown to work properly (this
is required in VSCode for instance).

(††) each of the four symbol is allowed in repl mode for respectively the
standard REPL (`>`), shell mode (`;`), pkg mode (`]`) and help mode (`?`).

Return a CodeInfo.

If the "!" or ":" is doubled (i.e. "!!" or "::") the cell will be evaluated
in all scenarios. This can be useful for debugging or force-refreshing a
cell but should otherwise not be used.
"""
function _code_info(
            b::Block,
            lc::LocalContext
        )::CodeInfo

    info = match(CODE_INFO_PAT, b.ss).captures[1]
    lang = getvar(lc, :lang, "")
    info === nothing && return CodeInfo(; lang, code=_strip(content(b)))

    info = string(info)
    cb   = content(b)
    code = subs(cb, nextind(cb, lastindex(info)), lastindex(cb)) |> _strip

    name   = ""
    exec   = false
    auto   = false
    force  = false
    indep  = false

    l, e, n = match(CODE_LANG_PAT, info)

    if !isnothing(l)
        lang = l
    end
    if !isnothing(e)
        exec = true
        if e == ">"
            lang = "repl-repl"
        elseif e == ";"
            lang = "repl-shell"
        elseif e == "?"
            lang = "repl-help"
        elseif e == "]"
            lang = "repl-pkg"
        end
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

            name  = auto_cell_name(lc)
            name *= ifelse(isempty(name_hint), "", " ($name_hint)")
            auto  = true
        end
        # If there's a doubling of `!` or `:` then the cell should
        # be force re-executed.
        if length(e) == 2
            force = true
        end
        # If there's an '# indep' on a line, then mark the code
        # as indep
        m = match(CODE_INDEP_PAT, code)
        if !isnothing(m)
            indep = true
            code  = replace(code, CODE_INDEP_PAT => "\n")
        end
    end

    return CodeInfo(;
        name,
        lang,
        code=strip(code, ['\n']),
        exec,
        auto,
        force,
        indep
    )
end


"""
    auto_cell_name(lc)

Assign a name to a code cell based on the notebook counter (and increment
the notebook counter).
"""
function auto_cell_name(
            lc::LocalContext
        )::String

    cntr  = getvar(lc, :_auto_cell_counter, 0)
    cntr += 1
    setvar!(lc, :_auto_cell_counter, cntr)
    cell_name = "auto_cell_$cntr"
    return cell_name
end


"""
    html_code_block(b, c)

Represent a code block `b` as HTML in the local context `lc`.
"""
function html_code_block(
            b::Block,
            lc::LocalContext
        )::String

    hascode!(lc)
    ci = _code_info(b, lc)
    if ci.exec && startswith(ci.lang, "repl-")
        return html_repl_code(ci, lc)
    end
    # placeholder for output string if has to be added directly after code
    # might remain empty if result is nothing or if it's not an auto-cell
    post = ""
    if ci.exec
        if ci.lang == "julia"
            imgdir_base  = mkpath(path(lc.glob, :site) / "assets" / noext(lc.rpath))
            imgdir_html  = mkpath(imgdir_base / "figs-html")
            imgdir_latex = mkpath(imgdir_base / "figs-latex")
            eval_code_cell!(
                lc, ci.code, ci.name;
                imgdir_html, imgdir_latex,
                # code info
                force=ci.force,
                indep=ci.indep
            )
        end
        if ci.auto
            post = lx_show(lc, [ci.name])
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
    latex_code_block(b, lc)

Represent a code block `b` as LaTeX in the local context `lc`.
"""
function latex_code_block(
            b::Block,
            lc::LocalContext
        )::String

    ci = _code_info(b, lc)
    if ci.exec && startswith(ci.lang, "repl-")
        return latex_repl_code(ci, lc)
    end
    if ci.exec
        if ci.lang == "julia"
            eval_code_cell!(lc, ci.code, ci.name; force=ci.force)
        end
        if ci.auto
            post = lx_show(lc, [ci.name]; tohtml=false)
        end
        code = ci.code |> _hide_lines |> _hescape
    else
        code = ci.code |> _hescape
    end
    return ifelse(isempty(code), "", """
        \\begin{lstlisting}\n$code\n\\end{lstlisting}
        """) * post
end


# ============================================================================
#
# REPL MODE
#
# ============================================================================


function html_repl_code(
    ci::CodeInfo,
    lc::LocalContext
)::String

    io = IOBuffer()
    _eval_repl_code(io, ci, lc; tohtml=true)
    return String(take!(io))
end

function latex_repl_code(
    ci::CodeInfo,
    lc::LocalContext
)::String

    io = IOBuffer()
    _eval_repl_code(io, ci, lc; tohtml=false)
    return String(take!(io))
end

"""
    _eval_repl_code

Evaluate the repl-mode code appropriately and output the formatted result in
the iostream so it can be recuperated.
"""
function _eval_repl_code(
        io::IOBuffer,
        ci::CodeInfo,
        lc::LocalContext;
        tohtml::Bool=true
    )::Nothing
   
    if !tohtml
        println(io, raw"\begin{lstlisting}")
    else
        print(io, "<pre><code class=\"julia-repl\">")
    end

    #
    # REPL-REPL mode
    # HACK: for now assumption of non-incomplete AST expressions
    #
    if ci.lang == "repl-repl"

        # if that code has not been seen yet or, if it has and has changed,
        # force eval so that all lines get re-executed 
        prev_hash = get(lc.nb_code.repl_code_hash, ci.name * "_0", UInt64(0))
        cur_hash  = hash(ci.code)
        force     = prev_hash != cur_hash

        chunk   = ""
        counter = 1
        for line in split(ci.code, r"\r?\n", keepempty=false)
            # add to the chunk until we have a complete AST
            chunk *= line * "\n"
            ast = Base.parse_input_line(chunk)
            if (isa(ast, Expr) && ast.head === :incomplete)
                continue
            else
                # now 'chunk' corresponds to a complete ast
                chunk_name = ci.name * "_$counter"
                eval_code_cell!(
                    lc, SubString(chunk), chunk_name; repl_mode=true, force
                )
                idx = findfirst(==(chunk_name), lc.nb_code.code_names)::Int

                counter > 1 && println(io, "")
                if tohtml
                    println(io, ansi("\e[1m\e[32mjulia>\e[0m $(strip(chunk))"))
                    rep = strip(lc.nb_code.code_pairs[idx].repr.ansi)
                else
                    println(io, "julia> $(strip(chunk))")
                    rep = strip(lc.nb_code.code_pairs[idx].repr.raw)
                end
                isempty(rep) || println(io, strip(rep))

                chunk    = ""
                counter += 1
            end
        end
        lc.nb_code.repl_code_hash[ci.name * "_0"] = cur_hash

    #
    # REPL-SHELL mode
    #
    elseif ci.lang == "repl-shell"
        counter = 1
        for line in split(ci.code, r"\r?\n", keepempty=false)
            captured = IOCapture.capture(color=true) do
                Base.repl_cmd(Cmd(string.(split(line))), nothing)
            end
            counter > 1 && println(io, "")
            if tohtml
                println(io, ansi("\e[1m\e[31mshell>\e[0m $(strip(line))"))
                isempty(captured.output) || println(io, ansi(strip(captured.output)))
            else
                println(io, "shell> $(strip(line))")
                isempty(captured.output) || println(io, strip(captured.output))
            end
            counter += 1
        end
    
    #
    # REPL-PKG mode
    #
    elseif ci.lang == "repl-pkg"
        counter = 1
        for line in split(ci.code, r"\r?\n", keepempty=false)
            tmp = tempname()
            project_name = splitpath(Pkg.project().path)[end-1]
            captured = IOCapture.capture(color=true) do
                Pkg.REPLMode.pkgstr(string(line))
            end
            counter > 1 && println(io, "")
            if tohtml
                println(io, ansi("\e[1m\e[34m($(project_name)) pkg>\e[0m $(strip(line))"))
                isempty(captured.output) || println(io, ansi(strip(captured.output)))
            else
                println(io, "($(project_name)) pkg> $(strip(line))")
                isempty(captured.output) || println(io, strip(captured.output))
            end
        end
    
    #
    # REPL-HELP mode
    #
    else
        # only the first line is considered, rest ignored
        line = first(split(ci.code, r"\r?\n", limit=2))
        r    = lc.nb_code.mdl.eval(Meta.parse("@doc $line"))

        # close code first, then print result
        if !tohtml
            println(io, "help?> $(strip(line))")
            println(io, raw"\end{lstlisting}")
            println(io, strip(Markdown.latex(r)))
        else
            println(io, ansi("\e[1m\e[33mhelp?>\e[0m $(strip(line))"))
            # We use the Markdown html processor here so that the output
            # is similar to the REPL, for instance so that we don't have
            # to fiddle with footnotes which are processed differently.
            println(io, "</code></pre>")
            println(io, "<div class=\"repl-help\">")
            println(io, strip(replace(
                Markdown.html(r),
                r"<a href=\"@ref(.*?)\">(.*?)</a>" => s"\1",
                "class=\"language-jldoctest\""     => "class=\"language-julia-repl\"",
                r"(?:\&\#36\;)+((.|\n)*?)(?:\&\#36\;)+" => s"\\(\1\\)"
            )))
            println(io, "</div>")
        end
    end

    if ci.lang != "repl-help"
        if !tohtml
            println(io, raw"\end{lstlisting}")
        else
            println(io, "</code></pre>")
        end
    end    
    return
end
