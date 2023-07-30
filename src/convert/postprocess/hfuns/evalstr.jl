"""
    is_estr(s)

Check if a candidate string looks like an e-string:
* starts with `e"`
* starts with `>`
* starts with `!>`
"""
function is_estr(s)
    startswith(s, "e\"") && return true
    startswith(s, r"!?>") && return true
    return false
end


"""
    eval_str(lc, estr)

Take an e-string `e"..."` replace any `\$...` with a locvar getter and evaluate
the logic in the current utils module.

Note that this is a bit slow because of the way the code is evaluated in the
Utils module whilst keeping track of whether the code executed fine or not and
capturing the results. So the recommendation for users is to use this
occasionally for simple logic; otherwise write a hfun.

See tests for examples.
"""
function eval_str(
            lc::LocalContext,
            estr::SS
        )::EvalResult

    estr = replace(strip(estr), "\\\"" => "⁰")
    if startswith(estr, "e")
        estr = strip(strip(lstrip(estr, 'e'), '\"'))
    else
        estr = strip(replace(estr, r"^\!?\>" => ""))
    end
    code = _eval_str(lc, estr)
    code = replace(code, "⁰" => "\"")

    res = eval_nb_cell(
        get_utils_module(lc),
        code,
        cell_name = "__estr__"
    )

    return res
end
eval_str(lc, es::String) = eval_str(lc, subs(es))
eval_str(es::String)     = eval_str(ToyLocalContext(), es)


"""
    _eval_str(lc, code)

Go over code looking for un-escaped dollar signs and replace those with locvar
injections.
"""
function _eval_str(
            lc::LocalContext,
            code::SS
        )::String

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
                    # we use getvarfrom because this will be evaluated in the
                    # Utils module which doesn't have an LC set.
                    str = "getvarfrom(:$varname, \"$(lc.rpath)\")"
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
    return code
end
