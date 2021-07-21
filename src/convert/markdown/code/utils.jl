#=
Functionalities to generate a sandbox module.
=#

"""
    modulename(fpath)

Return a sandbox module name corresponding to the page at `fpath`.
"""
modulename(fpath::AbstractString) = "__FRANKLIN_SANDBOX_$(hash(fpath))"

"""
    ismodule(name)

Checks whether a name is a defined module.
"""
function ismodule(name::String)::Bool
    s = Symbol(name)
    isdefined(Main, s) || return false
    typeof(getfield(Main, s)) === Module
end

"""
    newmodule(name)

Creates a new module with a given name, if the module exists, it is wiped.
Discards the warning message that a module is replaced which may otherwise
happen. Return a handle pointing to the module.
"""
function newmodule(name::String)::Module
    mod = nothing
    mktemp() do _, outf
        # discard the "WARNING: redefining module X"
        redirect_stderr(outf) do
            mod = Core.eval(Main, Meta.parse("""
                module $name
                    using $(env(:MODULE_NAME))
                end
                """)
            )
        end
    end
    return mod
end


#=
Functionalities to take a string corresponding to Julia code and evaluate
that code in a given module while capturing stdout and redirecting it to
a file.
=#

"""
    parse_code(code)

Consume a string with Julia code, return a vector of expression(s).

Note: this function was adapted from the `parse_input` function from Weave.jl.
"""
function parse_code(code::SS)
    exs = Any[]         # Expr, Symbol or Any Julia core value
    n   = sizeof(code)
    pos = 1
    while pos ≤ n
        ex, pos = Meta.parse(code, pos)
        isnothing(ex) && continue
        push!(exs, ex)
    end
    exs
end


"""
    trim_stacktrace(error_string)

Returns only the stack traces which are related to the user's code.
This means removing stack traces pointing to Franklin's code.
Return the string as-is if the format is unrecognized.
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
