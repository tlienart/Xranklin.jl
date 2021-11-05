struct EvalStrError end

"""
    eval_str(estr)

Take an e-string `e"..."` replace any `\$...` with a locvar getter and evaluate
the logic in the current utils module.
See tests for examples.
"""
function eval_str(estr::SS)::Any
    estr     = strip(lstrip(strip(estr), 'e'), '\"')
    code     = _eval_str(estr)
    captured = (value=nothing, output="")
    try
        captured = IOCapture.capture() do
            include_string(softscope, cur_utils_module(), code)
        end
    catch e
        return EvalStrError()
    end
    return captured.value
end
eval_str(es::String) = eval_str(subs(es))


# e"foo($bar)" --> "foo(getlvar(:bar))"
# (the resulting string can then be evaluated in the utils code module so has access to functions there)
function _eval_str(code::SS)
    main_io = IOBuffer()
    tmp_io  = IOBuffer()
    prev    = '\0'
    open    = false
    idx     = 0
    nchars  = length(code)
    # look over each character, if a there's an unescaped $ then
    # grab the next relevant characters while they're valid
    for (i, cur) in enumerate(code)
        # if we see an un-escaped dollar, flag open (only starting from next char)
        if prev != '\\' && cur == '$'
            open = true
        elseif open
            # here we're in the scope of a $...; take chars while they verify
            # the is_id* base function. write that to a temporary pipe (tmp_io)
            # and purge that when you get to the "end" of the identifier (either
            # the end of the string or if we see a non id character like a wsp).
            at_end    = (i == nchars)
            take_char = (idx == 0 && Base.is_id_start_char(cur)) || (
                         idx >= 1 && Base.is_id_char(cur))
            if take_char
                write(tmp_io, cur)
                idx += 1
            end
            if !take_char || at_end
                # might be empty
                varname = String(take!(tmp_io))
                if !isempty(varname)
                    str = "getlvar(:$varname)"
                    write(main_io, str)
                end
                take_char || write(main_io, cur)
                open = false
                idx  = 0
            end
        else
            write(main_io, cur)
        end
        prev = cur
    end
    code = String(take!(main_io))
end
