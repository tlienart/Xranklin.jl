#=
Functionalities to take a string corresponding to Julia code and evaluate
that code in a given module while capturing stdout and redirecting it to
a file.
=#


"""
    run_code(mdl, code, out_path; exs=)

Run some code in a given module while redirecting stdout to a given path.
Return the result of the evaluation or `nothing` if the code was empty or
the evaluation failed. If the evaluation errors, the error is printed to
output and a warning is shown.

## Arguments

    `mod`:       the module in which to evaluate the code,
    `code`:      substring corresponding to the code,
    `out_path`:  path where stdout should be redirected

## Keyword

    `block_name`:  name of the block to indicate what is being run, can be
                   empty

## Return

Either `nothing` if the code fails or nothing is meant to be returned or the last
value of the cell.

Dev Note: the redirect and parsing etc incurs an overhead of the order of 1ms
this is deemed accetable since `run_code` would only be run on code cell and
the user would expect their code to take some time as well anyway.
"""
function run_code(
            mod::Module,
            code::SS,
            out_path::String=tempname();
            block_name::String=""
            )

    isempty(code) && return nothing

    res  = nothing         # to capture final result
    err  = nothing         # to capture any error
    stacktrace = nothing   # to capture stacktrace
    ispath(out_path) || mkpath(dirname(out_path))

    @info """
        ⏳ evaluating code... $(
            hl(isempty(block_name) ? "" : "($block_name)", :light_green))
        """
    start = time()
    open(out_path, "w") do outf
        redirect_stdout(outf) do
            try
                res = include_string(softscope, mod, code)
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
        @warn """
            Code evaluation
            ---------------
            There was an error of type '$err' when running a code block.
            Checking the output files '$(splitext(out_path)[1]).(out|res)'
            might be helpful to understand and solve the issue.

            Details:
            $(trim_stacktrace(stacktrace))
            """
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
    n   = sizeof(code)
    pos = 1
    lex = nothing  # last expression
    while pos ≤ n
        ex, pos = Meta.parse(code, pos)
        isnothing(ex) && continue
        lex = ex
    end
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
        @debug "Unrecognized stack trace:\n$s" exception = (err, catch_backtrace())
        return s
    end
end
