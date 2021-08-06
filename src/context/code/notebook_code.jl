"""
    eval_code_cell!(ctx, cell_code; cell_name)

Evaluate the content of a cell we know runs some code.
"""
function eval_code_cell!(
            ctx::Context, cell_code::SS;
            cell_name::String="", out_dir::String=tempdir()
            )::Nothing

    isempty(cell_code) && return

    nb   = ctx.nb_code
    cntr = counter(nb)
    code = cell_code |> strip |> string

    # skip cell if previously seen and unchanged
    isunchanged(nb, cntr, code) && (increment!(nb); return)

    # eval cell and write to file
    cname    = ifelse(isempty(cell_name), "auto", cell_name)
    out_path = out_dir / "__$(cntr)_$(cname).out"
    isfile(out_path) && rm(out_path)
    _eval_code_cell(nb.mdl, code, out_path, cell_name)
    out_str  = ""
    isfile(out_path) && (out_str = read(out_path, String))
    # if an id was given, keep track (if none was given, the empty string
    # links to lots of stuff, like "ans" in a way)
    nb.code_map[cell_name] = cntr
    return finish_cell_eval!(nb, CodeCodePair((code, out_str)))
end

"""
    _eval_code_cell(mdl, code)

Helper function to `eval_code_cell!`. Returns the result corresponding to the
execution of the code in module `mdl`.
"""
function _eval_code_cell(mdl::Module, code::String,
                         out_path::String, cell_name::String)::Nothing

    result     = nothing   # to capture final result
    err        = nothing   # to capture any error
    stacktrace = nothing   # to capture stacktrace
    ispath(out_path) || mkpath(dirname(out_path))

    start = time(); @debug """
    ⏳ evaluating code cell... $(
        hl(isempty(cell_name) ? "" : "($cell_name)", :light_green))
    """
    open(out_path, "w") do outf
        # things like printlns etc
        redirect_stdout(outf) do
            # things like @warn (errors are caught and written to stdout)
            redirect_stderr(outf) do
                try
                    result = include_string(softscope, mdl, code)
                catch e
                    # write the error to stdout + process the stacktrace and
                    # show it in the console
                    io = IOBuffer()
                    showerror(io, e)
                    # write the error to stdout
                    println(String(take!(io)))
                    err = typeof(e)
                    if VERSION >= v"1.7.0-"
                        exc, bt = last(Base.current_exceptions())
                    else
                        exc, bt = last(Base.catch_stack())
                    end
                    # retrieve the stacktrace string so it can be shown in repl
                    stacktrace = sprint(showerror, exc, bt)
                 end
             end
        end
    end
    # if there was an error, return nothing and possibly show warning
    if !isnothing(err)
        msg = """
              Code evaluation
              ---------------
              There was an error of type '$err' when running a code block.
              Checking the output file '$(out_path)'
              might be helpful to understand and solve the issue.
              Details:
              $(trim_stacktrace(stacktrace))
              """
        @warn msg
        env(:strict_parsing)::Bool && throw(msg)
        return nothing
    else
        δt = time() - start; @debug """
                ... [code cell] ✔ $(hl(time_fmt(δt)))
                """
    end

    # Check what should be displayed at the end if anything
    endswith(code, HIDE_FINAL_OUTPUT_PATTERN) && return nothing
    append_result(out_path, code, result)
    return
end

"""
    append_result(out_path, code, result)

Write a representation of the result to `out_path`.
"""
function append_result(out_path::String, code::String, result::R) where R
    # check if the last expression is a SHOW, if it is, then
    # don't do anything to avoid double printing since the
    # SHOW was already captured in STDOUT
    lex = last(parse_code(code))
    is_show = isa(lex, Expr) &&
                length(lex.args) > 1 &&
                lex.args[1] == Symbol("@show")
    is_show && return

    # Try to see if there's a custom Base.show with MIME("text/html")
    # for the type of Result, and if so use that, otherwise fall back to Base.show
    open(out_path, "a") do outf
        redirect_stdout(outf) do
            if hasmethod(Base.show, (IO, MIME"text/html", R))
                Base.show(stdout, MIME("text/html"), result)
            else
                Base.show(stdout, result)
            end
        end
    end
    return
end

append_result(::String, ::String, ::Nothing) = nothing


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
