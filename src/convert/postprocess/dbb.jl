const EMPTY_DBB     = "__EMPTY_DBB__"
const EMPTY_DBB_PAT = Regex("(?:<p>\\s*$(EMPTY_DBB)\\s*</p>)|(?:$(EMPTY_DBB))")


function resolve_dbb(
            io::IOBuffer,
            parts::Vector{Block},
            idx::Int,
            c::Context,
            gc::GlobalContext,
            lc::Union{Nothing, LocalContext}
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
        _dbb_fill_estr(io, cb)
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
            resolve_henv(henv, io, c)
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
    elseif (u = fname in utils_hfun_names()) || fname in INTERNAL_HFUNS
        # run the function either in the Utils module or internally
        mdl = ifelse(u, gc.nb_code.mdl, @__MODULE__)
        _dbb_fun(io, fname, args, mdl, gc, lc)

    # C | fill attempt
    else
        _dbb_fill(io, fname, args, dots, gc, lc)

    end
    return idx
end


function _dbb_fill_estr(
            io::IOBuffer,
            cb::SubString
        )::Nothing

    v = eval_str(cb)

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
            io::IOBuffer,
            fname::Symbol,
            args::Vector{String},
            mdl::Module,
            gc::GlobalContext,
            lc::Union{Nothing, LocalContext}
        )::Nothing

    fsymb = Symbol("hfun_$fname")
    f     = getproperty(mdl, fsymb)
    out   = outputof(f, args; tohtml=true)
    if isempty(out)
        write(io, EMPTY_DBB)
    else
        write(io, out)
    end

    # re-set current local and global context, just in case these were
    # changed by the call to the hfun (e.g. by triggering a processing)
    set_current_global_context(gc)
    lc === nothing || set_current_local_context(lc)
    return
end


function _dbb_fill(
            io::IOBuffer,
            fname::Symbol,
            args::Vector{String},
            dots::String,
            gc::GlobalContext,
            lc::Union{Nothing, LocalContext}
        )::Nothing

    res  = ""
    fail = !isempty(args)

    # try fill from LC
    if !fail && lc !== nothing && ((v = getvar(lc, fname)) !== nothing)
        res = string(v)

    # try fill from GC
    elseif !fail && ((v = getvar(gc, fname)) !== nothing)
        res = string(v)

    # try fill from Utils
    elseif !fail && (fname in utils_var_names())
        mdl = gc.nb_code.mdl
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
