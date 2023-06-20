# VarsNotebook and CodeNotebook do different things with their code cells,
# mostly in terms of how they recuperate and handle results.
#
# The VarsNotebook cares about *assignments* and so tries to recover that,
# The CodeNotebook cares about *results* and so tries to capture that.
#
# The core of each is essentially the same though:
#
#   1. get a code cell
#   2. hold the lock (to guarantee execution is done fully in one notebook)
#   3. try to run the code
#   4. recuperate results, stacktrace etc
#   5. release the lock
#   6. handle the results
#
# On top of that there may be some amount of information about the code being
# evaluated etc.
#
disable_warn()  = Logging.disable_logging(Logging.Warn)
get_loglevel()  = Base.CoreLogging._min_enabled_level[]
set_loglevel(l) = (Base.CoreLogging._min_enabled_level[] = l;)


struct EvalResult{T}
    success::Bool
    value::T
    out::String    # prints to stdout
    err::String    # prints to stderr
end
eval_result(; kw...) = EvalResult(
    kw[:success],
    kw[:value],
    kw[:out],
    kw[:err]
)


"""
    eval_nb_cell(mdl, code; cell_name)

Evaluate code `code` in module `mdl` where the code cell possibly has a name
`cell_name` attached to it (the latter is only true for code cells, var
assignment cells don't have a name).
"""
function eval_nb_cell(
            mdl::Module,
            code::String;
            cell_name::String=""
        )::EvalResult

    lock(env(:lock))
    cn = ifelse(
        isempty(cell_name),
        "vars-assignment",
        ifelse(
            cell_name == "__estr__",
            "e-string",
            cell_name
        )
    )
    start    = time(); @debug """
            ⏳ evaluating code... $(hl(cn, :light_green))
        """
    loglevel = get_loglevel()

    success = false
    value   = nothing
    out     = ""
    err     = ""
    
    try
        out, value = _attempt_eval(mdl, code)
        success    = true
        δt = time() - start; @debug """
            ... [$(hl("cell", :blue)): $(hl(cn, :light_green))] ✔ $(hl(time_fmt(δt)))
            """
    catch
        err = _process_eval_error(; cell_name)
    finally
        set_loglevel(loglevel)
        unlock(env(:lock))
    end

    return eval_result(; success, value, out, err)
end


function _attempt_eval(mdl::Module, code::String)
    captured = IOCapture.capture() do
        include_string(softscope, mdl, code)
    end
    return captured.output, captured.value
end


function _process_eval_error(; cell_name::String="")
    # also write to REPL so the user is doubly aware
    # if we're in 'strict_parsing' mode then this will throw
    # and interrupt the server
    if VERSION >= v"1.7.0-"
        exc, bt = last(Base.current_exceptions())
    else
        exc, bt = last(Base.catch_stack())
    end
    # retrieve the stacktrace string so it can be shown in repl
    stacktrace = sprint(showerror, exc, bt) |> trim_stacktrace
    
    isvar = isempty(cell_name)
    head  = ifelse(isvar, "Variables assignment code", "Code")
    cname = ifelse(isvar, "", "('$cell_name')") 
    msg   = """
        <$head evaluation>
        An error was caught when attempting to run code $cname
        Details:
        $stacktrace
        """
    env(:strict_parsing) && throw(msg)
    @warn msg
    return stacktrace
end
