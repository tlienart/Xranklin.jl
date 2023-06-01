"""
    eval_code_cell!(ctx, cell_code, cell_name; kw...)

Evaluate the content of a cell we know runs some code.

## Args

    ctx:       context in which the code is evaluated
    cell_code: the code to evaluate
    cell_name: the name of the cell (possibly generated)

## Kwargs

    imgdir_html:   the directory used to save images for HTML output
    imgdir_latex:  the directory used to save images for LaTeX output

"""
function eval_code_cell!(
            ctx::Context,
            cell_code::SS,
            cell_name::String;
            imgdir_html::String=tempdir(),
            imgdir_latex::String=tempdir(),
            force::Bool=false,
            indep::Bool=false
            )::Nothing

    # stop early if there's no code to evaluate
    isempty(cell_code) && return
    env(:nocode) && cell_name != "utils" && return

    # recover the notebook context, the cell index we're looking at
    # and the hash of the code (used for autofigs)
    nb         = ctx.nb_code
    cell_index = counter(nb)
    cell_code  = string(cell_code)
    cell_hash  = hash(cell_code) |> string

    # if the cell_index is within the range of cell indexes, we replace the
    # name with the current cell name to guarantee we're using the latest name.
    if cell_index <= length(nb.code_names)
        nb.code_names[cell_index] = cell_name
        # skip cell if previously seen and unchanged
        if isunchanged(nb, cell_index, cell_code) && !force
            @info "  ⏩  skipping cell $cell_name (unchanged)"
            increment!(nb)
            return
        end
    else
        push!(nb.code_names, cell_name)
    end

    # if the cell is explicitly marked as independent, check if we don't
    # happen to already have a mapping for it
    if indep
        if cell_code in keys(nb.indep_code)
            @info "  ⏩  skipping cell $cell_name (independent 🌴)"
            code_pair = CodeCodePair((cell_code, nb.indep_code[cell_code]))
            return finish_cell_eval!(nb, code_pair, indep)
        end
    end

    # we now have some code that we should evaluate, first we check
    # whether the notebook is stale (e.g. if was loaded from cache)
    # If that's the case, then the entire notebook is re-run to make
    # sure all cells have been executed once so that the cell we have
    # now has the full notebook context.
    # There is one EXCEPTION to this: if the cell was marked as
    # independent (indep=true). In that case, the cell is assumed NOT
    # to depend on context and therefore previous cells are not reexec.
    if is_stale(nb) && !indep
        start = time(); @info """
              ❗ code notebook stale, refreshing...
              """
        # reeval all previous cells, we don't need to
        # keep track of vars assignments or whatever as they
        # can't have changed
        for tmp_idx = 1:cell_index-1
            @info "  💦  refreshing cell $(nb.code_names[tmp_idx])..."
            _eval_code_cell(
                nb.mdl,
                nb.code_pairs[tmp_idx].code,
                nb.code_names[tmp_idx]
            )
        end
        δt = time() - start; @info """
            ... [code notebook refresh] ✓ $(hl(time_fmt(δt)))"
            """
        fresh_notebook!(nb)
    end

    # Form autofigs paths
    autosavefigs = getvar(ctx, :autosavefigs, true)
    autoshowfigs = getvar(ctx, :autoshowfigs, true)
    skiplatex    = getvar(ctx, :skiplatex,    false)
    fig_id       = "__autofig_$(cell_hash)"
    fpath_html   = imgdir_html  / fig_id
    fpath_latex  = imgdir_latex / fig_id
    fig_html     = (
        save  = autosavefigs,
        show  = autoshowfigs,
        fpath = fpath_html
    )
    fig_latex    = (
        save  = autosavefigs,
        show  = autoshowfigs,
        fpath = fpath_latex
    )

    # evaluate the cell and capture the output
    @info "  ⏯️  evaluating cell $(hl(cell_name, :yellow))" *
          ifelse(indep, " 🌴 ...", "...")

    code_outp = _eval_code_cell(nb.mdl, cell_code, cell_name)
    code_repr = _form_code_repr(ctx, code_outp, fig_html, fig_latex, skiplatex)
    code_pair = CodeCodePair((cell_code, code_repr))

    if indep
        nb.indep_code[cell_code] = code_repr
    end

    return finish_cell_eval!(nb, code_pair, indep)
end


"""
    _eval_code_cell(mdl, code, cell_name)

Helper function to `eval_code_cell!`. Returns the output string corresponding
to the captured stdout+stderr and the value (or nothing if nothing is to be
shown).

# Return

    * std_out::String
    * std_err::String
    * result::T where T
"""
function _eval_code_cell(
                mdl::Module,
                code::String,
                cell_name::String
                )::Tuple

    start = time(); @debug """
        ⏳ evaluating code cell... $(hl(
            isempty(cell_name) ? "" : "($cell_name)",
            :light_green))
        """

    std_out = ""
    std_err = ""
    result  = nothing

    # discard mock lines
    io = IOBuffer()
    for line in split(code, '\n')
        m = match(CODE_MOCK_PAT, line)
        if isnothing(m)
            println(io, line)
        end
    end
    code = String(take!(io))

    # NOTE: IOCapture will capture stdout for all thread so we need to lock
    # in order to do this in sequence. This means that pages with code are
    # effectively processed sequentially (it's not the case with vars code
    # as the output of that is not captured)
    # same as well with the _min_enabled_level thing actually...
    # ------------------------------------------------------------------------
    lock(env(:lock))

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
              <Code evaluation>
              An error was caught when attempting to run a code cell ('$(cell_name)')
              Details:
              $stacktrace
              """
        @warn msg
        env(:strict_parsing)::Bool && throw(msg)

        return (std_out, std_err, result)

    finally
        unlock(env(:lock))

    end
    # ------------------------------------------------------------------------

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
        pc  = parse_code(code)
        if !isempty(pc)
            lex = last(pc)
            is_show = isa(lex, Expr) &&
                        length(lex.args) > 1 &&
                        lex.args[1] == Symbol("@show")

            is_show && (result = nothing)
        end
    end
    return std_out, std_err, result
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
    _form_code_repr(...)

Helper function to get a representation of the evaluation of a code cell.

## Steps

    1. representation of stdout if not empty
    2. representation of stderr if not empty
    3. representation of result if not nothing

## Note for figs

For figs which have a Base.show (via an import so any that would be generated
from a package such as Plots.jl, PyPlot.jl, etc), there is sometimes an info
printed to stdout about the installation of dependencies or some such (e.g.
Conda install matplotlib). This is unsightly. To reduce the nuisance, if
the function append_result_html returns "true", then we alter the stdout
representation and add a class "fig-stdout" which can more readily be
suppressed or enabled by the user via CSS (and will be suppressed by default).
"""
function _form_code_repr(
            ctx::Context,
            output::Tuple{String,String,<:Any},
            fig_html::NT,
            fig_latex::NT,
            skiplatex::Bool = false
        )::CodeRepr where NT <: NamedTuple

    # extract the raw stuff from the output tuple (from _eval_code_cell)
    std_out, std_err, result  = output
    io_html, io_latex, io_raw = IOBuffer(), IOBuffer(), IOBuffer()

    # (1) Representation of STDOUT (printout in a div)
    if !isempty(std_out)
        write(io_html,
            "<pre><code class=\"code-stdout language-plaintext\">",
            std_out,
            "</code></pre>"
        )
        write(io_latex, std_out)
        write(io_raw,   std_out, "\n")
    end

    # (2) Representation of STDERR (printout in a div)
    if !isempty(std_err)
        write(io_html,
            "<pre><code class=\"code-stderr language-plaintext\">",
            std_err,
            "</code></pre>"
        )
        write(io_latex, std_out)
    end

    # (3) Representation of the result
    figshow = false
    if !isnothing(result)
        # If there's a non-empty result, keep track of what it looks like
        write(
            io_raw,
            result isa AbstractString ?
                string(result) :
                Base.@invokelatest Base.repr(result)
        )
        # Check if there's a dedicated show or a custom show available
        figshow = append_result_html!(ctx, io_html, result, fig_html)
        skiplatex || append_result_latex!(ctx, io_latex, result, fig_latex)
    end

    hrepr, lrepr, rrepr = String.(take!.((io_html, io_latex, io_raw)))

    # see note
    if figshow
        hrepr = replace(hrepr,
                    "<pre><code class=\"code-stdout" =>
                    "<pre class=\"fig-stdout\"><code class=\"code-stdout")
    end

    return CodeRepr((hrepr, lrepr, rrepr))
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
function append_result_html!(
            ctx::Context,
            io::IOBuffer,
            result::R,
            fig::NamedTuple
        ) where R

    figshow = false
    Utils   = ctx.nb_code.mdl.Utils

    if isdefined(Utils, :html_show) && hasmethod(Utils.html_show, (R,))
        write(io, Utils.html_show(result))

    elseif fig.save && hasmethod(Base.show, (IO, MIME"image/svg+xml", R))
        _write_img(result, fig.fpath * ".svg", MIME("image/svg+xml"))
        fig.show && write(io, """
                <img class="code-figure" src="/$(get_ropath(cur_gc(), fig.fpath)).svg">
                """)
        figshow = true

    elseif fig.save && hasmethod(Base.show, (IO, MIME"image/png", R))
        _write_img(result, fig.fpath * ".png", MIME("image/png"))
        fig.show && write(io, """
                <img class="code-figure" src="/$(get_ropath(cur_gc(), fig.fpath)).png">
                """)
        figshow = true

    elseif hasmethod(Base.show, (IO, MIME"text/html", R))
        Base.@invokelatest Base.show(io, MIME("text/html"), result)

    else
        write(io, """<pre><code class="code-result language-plaintext">""")
        if hasmethod(Base.show, (IO, MIME"text/plain", R))
            Base.@invokelatest Base.show(io, MIME("text/plain"), result)
        else
            Base.@invokelatest Base.show(io, result)
        end
        write(io, """</code></pre>""")
    end
    return figshow
end


"""
    append_result_latex!(io, result)

Same as the one for HTML but for LaTeX.

Note: SVG support in LaTeX is not straightforward (depends on other tools).
"""
function append_result_latex!(
            ctx::Context,
            io::IOBuffer,
            result::R,
            fig::NamedTuple
        ) where R

    Utils = ctx.nb_code.mdl.Utils

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

    elseif hasmethod(Base.show, (IO, MIME"text/latex", R))
        Base.@invokelatest Base.show(io, MIME("text/latex"), result)

    else
        if hasmethod(Base.show, (IO, MIME"text/plain", R))
            Base.@invokelatest Base.show(io, MIME("text/plain"), result)
        else
            Base.@invokelatest Base.show(io, result)
        end
    end
    return
end

# shortcuts
append_result_html!(::Context, ::IOBuffer,  ::Nothing, ::NamedTuple) = nothing
append_result_latex!(::Context, ::IOBuffer, ::Nothing, ::NamedTuple) = nothing

function _write_img(result::R, fp::String, mime::MIME) where R
    open(fp, "w") do img
        Base.@invokelatest Base.show(img, mime, result)
    end
    return
end
