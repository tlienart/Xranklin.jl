"""
    run(mdl, code, out_path; exs=)

Run some code in a given module while redirecting stdout to a given path.
Return the result of the evaluation or `nothing` if the code was empty or
the evaluation failed.
If the evaluation errors, the error is printed to output then a warning is
shown.

## Arguments

    `mod`:      the module in which to evaluate the code,
    `code`:     substring corresponding to the code,
    `out_path`: path where stdout should be redirected

## Keyword

    `exs`:      list of expressions corresponding to the parsed code, may
                have already been generated (e.g. in the case of md defs)
"""
function run_code(
            mod::Module,
            code::SS,
            out_path::String=tempname();
            exs::Vector=[]
            )

    isempty(code) && return nothing
    isempty(exs) && (exs = parse_code(code))

    ne   = length(exs)
    res  = nothing        # to capture final result
    err  = nothing        # to capture any error
    stacktrace = nothing
    ispath(out_path) || mkpath(dirname(out_path))

    open(out_path, "w") do outf
        redirect_stdout(outf) do
            e = 1
            while e <= ne
                try
                    res = Core.eval(mod, exs[e])
                catch e
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

                    break
                end
                e += 1
            end
        end
    end

    # if there was an error, return nothing and possibly show warning
    if !isnothing(err)
        print_warning(
            """
            There was an error of type '$err' when running a code block.
            Checking the output files '$(splitext(out_path)[1]).(out|res)'
            might be helpful to understand and solve the issue.

            Details:
            $(trim_stacktrace(stacktrace))
            """
        )
        res = nothing
    end

    # Check what should be displayed at the end if anything
    endswith(code, HIDE_FINAL_OUTPUT_PATTERN) && return nothing
    # if last line is a Julia value return
    isa(exs[end], Expr) || return res
    # if last line of the code is a `show`
    if length(exs[end].args) > 1 && exs[end].args[1] == Symbol("@show")
        return nothing
    end
    # otherwise return the result of the last expression
    return res
end
