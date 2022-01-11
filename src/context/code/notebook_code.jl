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

    # skip cell if previously seen and unchanged though check in case the
    # cell name changed and if so, adjust
    if isunchanged(nb, cntr, code)
        @info "  ⏩  skipping cell $cell_name (unchanged)"
        for (name, i) in nb.code_map
            if i == cntr
                if name != cell_name
                    pop!(nb.code_map, name)
                    nb.code_map[cell_name] = cntr
                end
                break
            end
        end
        increment!(nb)
        return
    end

    if isstale(nb)
        start = time(); @info """
              ❗ code notebook stale, refreshing...
            """
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
        δt = time() - start; @info """
            ... [code notebook refresh] ✓ $(hl(time_fmt(δt)))"
            """
        fresh_notebook!(nb)
    end

    # eval cell
    @info "  ⏯️  evaluating cell $cell_name..."
    std_out, std_err, result = _eval_code_cell(nb.mdl, code, cell_name)

    autosavefigs = getvar(ctx, :autosavefigs, true)
    autoshowfigs = getvar(ctx, :autoshowfigs, true)
    fig_id       = "__autofig_$(hash(code))"
    fpath_html   = imgdir_html / fig_id
    fpath_latex  = imgdir_latex / fig_id
    fig_html     = (save=autosavefigs, show=autoshowfigs, fpath=fpath_html)
    fig_latex    = (save=autosavefigs, show=autoshowfigs, fpath=fpath_latex)

    # form the string representation of the cell. This is in  two  parts
    # (1) the stdout (output) if there's a println for instance
    # (2) the show(result) which can be overwritten by the user if they
    #     want specific objects to have a specific HTML or LaTeX repr
    io_html  = IOBuffer()
    io_latex = IOBuffer()
    if !isempty(std_out)
        write(io_html,
            "<pre><code class=\"code-stdout language-plaintext\">",
            std_out,
            "</code></pre>"
        )
        write(io_latex, std_out)
    end
    if !isempty(std_err)
        write(io_html,
            "<pre><code class=\"code-stderr language-plaintext\">",
            std_err,
            "</code></pre>"
        )
        write(io_latex, std_out)
    end

    crumbs("eval_code_cell!", "[output to io]")

    append_result_html!(io_html, result, fig_html)
    append_result_latex!(io_latex, result, fig_latex)

    repr = CodeRepr((String(take!(io_html)), String(take!(io_latex))))

    crumbs("eval_code_cell!", "[formed repr]")

    # if an id was given, keep track (if none was given, the empty string
    # links to lots of stuff, like "ans" in a way)
    nb.code_map[cell_name] = cntr

    return finish_cell_eval!(nb, CodeCodePair((code, repr)))
end


const Captured = NamedTuple{     (:std_out, :std_err, :result),
                            Tuple{ String,    String,  T} where T }


"""
    _eval_code_cell(mdl, code, cell_name)

Helper function to `eval_code_cell!`. Returns the output string corresponding
to the captured stdout+stderr and the value (or nothing if nothing is to be
shown).

# Return

NamedTuple
    * value
    * output
"""
function _eval_code_cell(mdl::Module, code::String, cell_name::String)::Captured
    start = time(); @debug """
    ⏳ evaluating code cell... $(
        hl(isempty(cell_name) ? "" : "($cell_name)", :light_green))
    """
    std_out = ""
    std_err = ""
    result  = nothing

    # avoid Precompilation info and warning showing up in stdout
    pre_log_level = Base.CoreLogging._min_enabled_level[] # yeah.. I know
    Logging.disable_logging(Logging.Warn)

    try
        captured = IOCapture.capture() do
            include_string(softscope, mdl, code)
        end
        # if we're here then 'output' and 'value' are set
        std_out = captured.output
        result  = captured.value

        Base.CoreLogging._min_enabled_level[] = pre_log_level

    catch e
        # also write to REPL so the user is doubly aware
        # if we're in 'strict_parsing' mode then this will throw
        # and interrupt the server
        err = typeof(e)
        if VERSION >= v"1.7.0-"
            exc, bt = last(Base.current_exceptions())
        else
            exc, bt = last(Base.catch_stack())
        end
        # retrieve the stacktrace string so it can be shown in repl
        stacktrace = sprint(showerror, exc, bt) |> trim_stacktrace
        std_err    = stacktrace

        Base.CoreLogging._min_enabled_level[] = pre_log_level

        msg = """
              Code evaluation
              There was an error of type '$err' when running code '$(cell_name)'
              Details:
              $stacktrace
              """
        @warn msg
        env(:strict_parsing)::Bool && throw(msg)

        return (; std_out, std_err, result)
    end

    δt = time() - start; @debug """
            ... [code cell] ✔ $(hl(time_fmt(δt)))
            """

    # if the end of the cell is a ';' or a `@show` then
    # suppress the result
    if endswith(code, HIDE_FINAL_OUTPUT_PAT)
        result = nothing
    else
        # Check if the last expression is a show and if so set the returned
        # value to nothing to avoid double shows
        lex = last(parse_code(code))
        is_show = isa(lex, Expr) &&
                    length(lex.args) > 1 &&
                    lex.args[1] == Symbol("@show")

        is_show && (result = nothing)
    end
    return (; std_out, std_err, result)
end

"""
    trim_stacktrace(error_string)

Returns only the stack traces which are related to the user's code. This means
removing stack traces pointing to Franklin's code. Return the string as-is if
the format is unrecognised.
"""
function trim_stacktrace(s::String)
    try
        first_match_start = first(findfirst(STACKTRACE_TRIM_PAT, s))
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
    R === Nothing && return

    Utils = cur_utils_module()
    if isdefined(Utils, :html_show) && hasmethod(Utils.html_show, (R,))
        write(io, Utils.html_show(result))

    elseif fig.save && hasmethod(Base.show, (IO, MIME"image/svg+xml", R))
        _write_img(result, fig.fpath * ".svg", MIME("image/svg+xml"))
        fig.show && write(io, """
                <img class="code-figure" src="/$(get_ropath(fig.fpath)).svg">
                """)

    elseif fig.save && hasmethod(Base.show, (IO, MIME"image/png", R))
        _write_img(result, fig.fpath * ".png", MIME("image/png"))
        fig.show && write(io, """
                <img class="code-figure" src="/$(get_ropath(fig.fpath)).png">
                """)

    else
        write(io, """<pre><code class="code-result language-plaintext">""")
        # need invokelatest in case the cell includes a package which extends show
        Base.@invokelatest Base.show(io, result)
        write(io, """</code></pre>""")
    end
    return
end

"""
    append_result_latex!(io, result)

Same as the one for HTML but for LaTeX.

Note: SVG support in LaTeX is not straightforward (depends on other tools).
"""
function append_result_latex!(io::IOBuffer, result::R, fig::NamedTuple) where R
    R === Nothing && return

    Utils = cur_utils_module()
    if isdefined(Utils, :latex_show) && hasmethod(Utils.latex_show, (R,))
        write(io, Utils.latex_show(result))

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
        Base.@invokelatest Base.show(io, result)
    end
    return
end

# shortcuts
append_result_html!(::IOBuffer,  ::Nothing, ::NamedTuple) = nothing
append_result_latex!(::IOBuffer, ::Nothing, ::NamedTuple) = nothing

function _write_img(result::R, fp::String, mime::MIME) where R
    open(fp, "w") do img
        Base.@invokelatest Base.show(img, mime, result)
    end
    return
end
