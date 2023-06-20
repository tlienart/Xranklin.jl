const EMPTY_DBB     = "__EMPTY_DBB__"
const EMPTY_DBB_PAT = Regex("(?:<p>\\s*$(EMPTY_DBB)\\s*</p>)|(?:$(EMPTY_DBB))")


function resolve_dbb(
            io::IOBuffer,
            parts::Vector{Block},
            idx::Int,
            lc::LocalContext;
            only_external::Bool=false
        )::Int

    crumbs(@fname, (parts[idx].ss |> strip) * ifelse(only_external, " (only ext)", " (all)"))

    cb = strip(content(parts[idx]))

    #
    # Early skips: empty dbb
    #
    if isempty(cb)
        write(io, EMPTY_DBB)
        return idx
    end

    #
    # Actual DBB treatment
    # > A.  internal HENV (if, etc)
    # > A'. dangling HENV (orphan else, elseif, end)
    # > B.  e-string?
    # > C.  hfun
    # > D.  fill attempt
    # > E.  only_external
    #
    split_cb = FP.split_args(cb)
    fname    = Symbol(lowercase(first(split_cb)))
    args     = split_cb[2:end] # may be empty
    dots     = ifelse(isempty(args), "", " ...")

    # A | if and variations
    if (fname in INTERNAL_HENVS) & !only_external
        # find the full environment with branches etc
        henv, ci = find_henv(parts, idx, fname, args)
        # if an empty env is returned, it means the opening token
        # was not closed properly --> failed
        if isempty(henv)
            @warn """
                {{ ... }}
                ---------
                An environment '{{$fname$dots}}' was not closed properly.
                """
            write(io, hfun_failed(split_cb))
        else
            resolve_henv(lc, henv, io)
        end
        # move the head after the last seen token from find_henv
        idx = ci

    # A' | dangling {{elseif}}, {{else}} or {{end}}
    elseif (fname in INTERNAL_HORPHAN) & !only_external
        @warn """
            {{ ... }}
            ---------
            A block '{{$fname$dots}}' was found out of a relevant context.
            """
        write(io, hfun_failed(split_cb))

    # B | independent e-string (outside of henv)
    elseif is_estr(cb; allow_short = true) & !only_external
        _dbb_fill_estr(lc, io, cb)

    # C | utils function or internal function (utils have priority)
    elseif (external = fname in utils_hfun_names(lc.glob)) ||
           ((fname in INTERNAL_HFUNS) & !only_external)
        # run the function either in the Utils module or internally
        _dbb_fun(lc, io, fname, args; internal=!external)

    # D | fill attempt
    elseif !only_external
        _dbb_fill(lc, io, fname, args, dots)

    # E
    else
        # this is if only_external / we just re-write the command
        # for later processing
        write(io, parts[idx].ss)

    end

    return idx
end


function _dbb_fill_estr(
            lc::LocalContext,
            io::IOBuffer,
            cb::SubString
        )::Nothing

    res = eval_str(lc, cb)
    if res.success
        r = stripped_repr(res.value)
        if isempty(r)
            write(io, EMPTY_DBB)
        else
            write(io, r)
        end
    else
        # warning / throw handled by eval
        write(io, hfun_failed([string(cb)]))
    end
    return
end


function _dbb_fun(
            lc::LocalContext,
            io::IOBuffer,
            fname::Symbol,
            args::Vector{String};
            internal::Bool=true
        )::Nothing

    fsymb = Symbol("hfun_$fname")
    out   = outputof(fsymb, args, lc; tohtml=true, internal)
    if isempty(out)
        write(io, EMPTY_DBB)
    else
        write(io, out)
    end
    return
end


function _dbb_fill(
            lc::LocalContext,
            io::IOBuffer,
            fname::Symbol,
            args::Vector{String},
            dots::String
        )::Nothing

    res  = ""
    fail = !isempty(args)

    if !fail && ((v = getvar(lc, fname)) !== nothing)
        res = string(v)

    # try fill from Utils
    elseif !fail && (fname in utils_var_names(lc.glob))
        mdl = utils_module(lc)
        res = string(getproperty(mdl, fname))

    else
        fail = true
    end

    if fail
        @warn """
          {{ ... }}
          ---------
          A block '{{$fname$dots}}' was found but the name '$fname' does not
          correspond to a built-in block or hfun nor does it match anything
          defined in `utils.jl`. It might have been misspelled.
          """
        res = hfun_failed([string(fname), args...])
    end
    res = ifelse(isempty(res), EMPTY_DBB, res)
    write(io, res)
    return
end
