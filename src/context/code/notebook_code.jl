"""
    eval_code_cell!(ctx, cell_code; cell_name)

Evaluate the content of a cell we know runs some code.
"""
function eval_code_cell!(ctx::Context, cell_code::SS; cell_name::String="")::Nothing
    isempty(cell_code) && return

    nb   = ctx.nb_code
    cntr = counter(nb)
    h    = hash(cell_code)

    # skip cell if previously seen and unchanged
    isunchanged(nb, cntr, h) && (increment!(nb); return)

    # eval cell
    result = _eval_code_cell(nb.mdl, cell_code)
    # if an id was given, keep track (if none was given, the empty string
    # links to lots of stuff, like "ans" in a way)
    nb.code_map[cell_name] = cntr
    return finish_cell_eval!(nb, CodePair((h, result)))
end

"""
    _eval_code_cell(mdl, code)

Helper function to `eval_code_cell!`. Returns the result corresponding to the
execution of the code in module `mdl`.
"""
function _eval_code_cell(mdl::Module, code::SS;
                         out_path::String=tempname(), block_name::String="")

    res        = nothing   # to capture final result
    err        = nothing   # to capture any error
    stacktrace = nothing   # to capture stacktrace
    ispath(out_path) || mkpath(dirname(out_path))

    start = time(); @debug """
    ⏳ evaluating code... $(
        hl(isempty(block_name) ? "" : "($block_name)", :light_green))
    """
    open(out_path, "w") do outf
        redirect_stdout(outf) do
            try
                res = include_string(softscope, mdl, code)
            catch
                io = IOBuffer()
                showerror(io, e)
                println(String(take!(io)))
                err = typeof(e)
                if VERSION >= v"1.7.0-"
                    exc, bt = last(Base.current_exceptions())
                else
                    exc, bt = last(Base.catch_stack())
                end
                stacktrace = sprint(showerror, exc, bt)
             end
        end
    end
    # if there was an error, return nothing and possibly show warning
    if !isnothing(err)
    msg = """
          Code evaluation
          ---------------
          There was an error of type '$err' when running a code block.
          Checking the output files '$(splitext(out_path)[1]).(out|res)'
          might be helpful to understand and solve the issue.
          Details:
          $(trim_stacktrace(stacktrace))
          """
     @warn msg
     env(:strict_parsing)::Bool && throw(msg)
     return nothing
    else
     δt = time() - start
     @info """
         ... ✔ $(hl(time_fmt(δt)))
         """
    end

    # Check what should be displayed at the end if anything
    endswith(code, HIDE_FINAL_OUTPUT_PATTERN) && return nothing

    # parse the code to check what the last expression is and how
    # it should be displayed
    lex = last(parse_code(code))
    # if last expr is a Julia value (= to res), return
    isa(lex, Expr) || return res
    # if last expr is a `show`, return nothing
    if (length(lex.args) > 1) && (lex.args[1] == Symbol("@show"))
     return nothing
    end
    # otherwise return the result of the last expression
    return res
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
