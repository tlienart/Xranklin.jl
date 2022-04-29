const EMPTY_DBB     = "__EMPTY_DBB__"
const EMPTY_DBB_PAT = Regex("(?:<p>\\s*$(EMPTY_DBB)\\s*</p>)|(?:$(EMPTY_DBB))")


function resolve_dbb(
            io::IOBuffer,
            parts::Vector{Block},
            idx::Int,
            lc::LocalContext;
            only::Vector{Symbol}=Symbol[]
        )::Int

    crumbs(@fname)

    cb = strip(content(parts[idx]))

    #
    # Early skips: empty dbb or e-string
    #
    if isempty(cb)
        write(io, EMPTY_DBB)
        return idx
    elseif is_estr(cb; allow_short = true)
        _dbb_fill_estr(lc, io, cb)
        return idx
    end

    #
    # Actual DBB treatment
    # > A.  internal HENV (if, etc)
    # > A'. dangling HENV (orphan else, elseif, end)
    # > B.  hfun
    # > C.  fill attempt
    #
    split_cb = FP.split_args(cb)
    fname    = Symbol(lowercase(first(split_cb)))
    args     = split_cb[2:end] # may be empty
    dots     = ifelse(isempty(args), "", " ...")

    if !isempty(only) && fname ∉ only
        write(io, parts[idx].ss)
        return idx
    end

    # A | if and variations
    if fname in INTERNAL_HENVS
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
    elseif fname in INTERNAL_HORPHAN
        @warn """
            {{ ... }}
            ---------
            A block '{{$fname$dots}}' was found out of a relevant context.
            """
        write(io, hfun_failed(split_cb))

    # B | utils function or internal function (utils have priority)
    elseif (internal = fname in utils_hfun_names(lc.glob)) || fname in INTERNAL_HFUNS
        # run the function either in the Utils module or internally
        _dbb_fun(lc, io, fname, args, gc, lc; internal)

    # C | fill attempt
    else
        _dbb_fill(lc, io, fname, args, dots, gc, lc)

    end
    return idx
end


function _dbb_fill_estr(
            lc::LocalContext,
            io::IOBuffer,
            cb::SubString
        )::Nothing

    v = eval_str(lc, cb)

    if !isa(v, EvalStrError)
        sv = string(v)
        if isempty(sv)
            write(io, EMPTY_DBB)
        else
            write(io, sv)
        end
        return
    end

    @warn """
        {{ e"..." }} or {{ > ... }}
        ---------------------------
        An environment '{{ e"..." }}' failed to evaluate properly,
        check that the code in the e-string is valid and that
        variables are prefixed with a \$.
        """
    write(io, hfun_failed([string(cb)]))
end


function _dbb_fun(
            lc::LocalContext,
            io::IOBuffer,
            fname::Symbol,
            args::Vector{String};
            internal::Bool=true
        )::Nothing

    fsymb = Symbol("hfun_$fname")
    out   = outputof(fsymb, args, lc; tohtml=true)
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

    if !fail && (v = getvar(lc, fname) !== nothing)
        res = string(v)

    # try fill from Utils
    elseif !fail && (fname in utils_var_names())
        mdl = lc.glob.nb_code.mdl
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
