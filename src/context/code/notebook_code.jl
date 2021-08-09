"""
    eval_code_cell!(ctx, cell_code; kw...)

Evaluate the content of a cell we know runs some code.

## Args

    ctx:       context in which the code is evaluated.
    cell_code: the code to evaluate

## Kwargs

    cell_name:     the name of the code cell if any
    imgdir_html:   the directory used to save images for HTML output
    imgdir_latex:  the directory used to save images for LaTeX output

"""
function eval_code_cell!(
            ctx::Context, cell_code::SS;
            cell_name::String="",
            imgdir_html::String=tempdir(),
            imgdir_latex::String=tempdir(),
            )::Nothing

    isempty(cell_code) && return

    nb   = ctx.nb_code
    cntr = counter(nb)
    code = cell_code |> strip |> string

    # skip cell if previously seen and unchanged
    isunchanged(nb, cntr, code) && (increment!(nb); return)

    if isstale(nb)
        # reeval all previous cells, we don't need to
        # keep track of their vars or whatever as they haven't changed
        tempc = 1
        while tempc < cntr
            cell_name = findfirst(cm.second == tempc for cm in nb.code_map)
            if cell_name === nothing
                cell_name = ""
            end
            _eval_code_cell(
                nb.mdl,
                nb.code_pairs[tempc].code,
                cell_name
            )
            tempc += 1
        end
        fresh_notebook!(nb)
    end

    # eval cell
    result, output = _eval_code_cell(nb.mdl, code, cell_name)

    autosavefigs = getvar(ctx, :autosavefigs, true)
    autoshowfigs = getvar(ctx, :autoshowfigs, true)
    file_prefix  = "__$(cntr)_$(cell_name)"
    fpath_html   = imgdir_html / file_prefix
    fpath_latex  = imgdir_latex / file_prefix

    fig_html  = (save=autosavefigs, show=autoshowfigs, fpath=fpath_html)
    fig_latex = (save=autosavefigs, show=autoshowfigs, fpath=fpath_latex)

    # form the string representation of the cell (output + show of value)
    io_html  = IOBuffer()
    io_latex = IOBuffer()
    write(io_html,  output)
    write(io_latex, output)
    append_result_html!(io_html, result, fig_html)
    append_result_latex!(io_latex, result, fig_latex)
    repr = CodeRepr((String(take!(io_html)), String(take!(io_latex))))

    # if an id was given, keep track (if none was given, the empty string
    # links to lots of stuff, like "ans" in a way)
    nb.code_map[cell_name] = cntr

    return finish_cell_eval!(nb, CodeCodePair((code, repr)))
end

"""
    _eval_code_cell(mdl, code, cell_name)

Helper function to `eval_code_cell!`. Returns the output string corresponding
to the captured stdout+stderr and the value (or nothing if nothing is to be
shown).
"""
function _eval_code_cell(mdl::Module, code::String, cell_name::String)::NamedTuple

    start = time(); @debug """
    ⏳ evaluating code cell... $(
        hl(isempty(cell_name) ? "" : "($cell_name)", :light_green))
    """

    captured = (value=nothing, output="")
    try
        captured = IOCapture.capture() do
            include_string(softscope, mdl, code)
        end
    catch e
        # keep the string of the error so it can be displayed
        io = IOBuffer()
        showerror(io, e)
        err_out = String(take!(io))

        # also process & write to REPL
        err = typeof(e)
        if VERSION >= v"1.7.0-"
            exc, bt = last(Base.current_exceptions())
        else
            exc, bt = last(Base.catch_stack())
        end
        # retrieve the stacktrace string so it can be shown in repl
        stacktrace = sprint(showerror, exc, bt)

        msg = """
              Code evaluation
              ---------------
              There was an error of type '$err' when running code '$(cell_name)'
              Details:
              $(trim_stacktrace(stacktrace))
              """
        @warn msg
        env(:strict_parsing)::Bool && throw(msg)
        return (value=nothing, output=err_out)
    end

    δt = time() - start; @debug """
            ... [code cell] ✔ $(hl(time_fmt(δt)))
            """

    # Check what should be displayed at the end if anything
    if endswith(code, HIDE_FINAL_OUTPUT_PATTERN)
        return (value=nothing, output=captured.output)
    end

    # Check if the last expression is a show and if so set the returned
    # value to nothing to avoid double shows
    lex = last(parse_code(code))
    is_show = isa(lex, Expr) &&
                length(lex.args) > 1 &&
                lex.args[1] == Symbol("@show")
    if is_show
        return (value=nothing, output=captured.output)
    end

    return captured
end

"""
    trim_stacktrace(error_string)

Returns only the stack traces which are related to the user's code. This means
removing stack traces pointing to Franklin's code. Return the string as-is if
the format is unrecognised.
"""
function trim_stacktrace(s::String)
    try
        first_match_start = first(findfirst(STACKTRACE_TRIM_PATTERN, s))
        # Keep only everything before the regex match.
        return s[1:first_match_start-3]
    catch err
        @debug """
               Unrecognized stack trace:\n$s
               """ exception = (err, catch_backtrace())
        return s
    end
end


"""
    append_result_html!(io, result, fpath)

Append a string representation of the `result` to `io` when writing HTML.
If it's a figure object showable as SVG or PNG, then write it to `fpath.EXT`
automatically but do not include an include statement (that's up to the user
as they might want to add a specific class or alt).

Users can also overwrite this default saving of files by overloading the
HTML mime show or writing their own code in the cell.
"""
function append_result_html!(io::IOBuffer, result::R, fig::NamedTuple) where R
    Utils = cur_utils_module()
    if hasmethod(Utils.show, (IO, MIME"text/html", R))
        Base.show(io, MIME("text/html"), result)

    elseif fig.save && hasmethod(Base.show, (IO, MIME"image/svg+xml", R))
        _write_img(result, fig.fpath * ".svg", MIME("image/svg+xml"))
        fig.show && write(io, """
                <img class="code-output fig" src="/$(get_ropath(fig.fpath)).svg">
                """)

    elseif fig.save && hasmethod(Base.show, (IO, MIME"image/png", R))
        _write_img(result, fig.fpath * ".png", MIME("image/png"))
        fig.show && write(io, """
                <img class="code-output fig" src="/$(get_ropath(fig.fpath)).png">
                """)

    else
        Base.show(io, result)
    end
    return
end

"""
    append_result_latex!(io, result)

Same as the one for HTML but for LaTeX.

Note: SVG support in LaTeX is not straightforward (depends on other tools).
"""
function append_result_latex!(io::IOBuffer, result::R, fig::NamedTuple) where R
    Utils = cur_utils_module()

    if hasmethod(Utils.show, (IO, MIME"text/latex", R))
        Base.show(io, MIME("text/latex"), result)

    elseif fig.save && hasmethod(Base.show, (IO, MIME"application/pdf", R))
        _write_img(result, fig.fpath * ".pdf", MIME("application/pdf"))
        fig.show && write(io, """
                \\includegraphics{$(fig.fpath).pdf}">
                """)

    elseif fig.save && hasmethod(Base.show, (IO, MIME"image/png", R))
        _write_img(result, fig.fpath * ".png", MIME("image/png"))
        fig.show && write(io, """
                \\includegraphics{$(fig.fpath).png}">
                """)

    else
        Base.show(io, result)
    end
    return
end

# shortcuts
append_result_html!(::IOBuffer,  ::Nothing, ::NamedTuple) = nothing
append_result_latex!(::IOBuffer, ::Nothing, ::NamedTuple) = nothing

function _write_img(result::R, fp::String, mime::MIME) where R
    open(fp, "w") do img
        Base.show(img, mime, result)
    end
    return
end
