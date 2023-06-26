const EMPTY_DBB     = "__EMPTY_DBB__"
const EMPTY_DBB_PAT = Regex("(?:<p>\\s*$(EMPTY_DBB)\\s*</p>)|(?:$(EMPTY_DBB))")


function resolve_dbb(
            io::IOBuffer,
            parts::Vector{Block},
            idx::Int,
            lc::LocalContext;
            only_utils::Bool=false
        )::Int

    crumbs(@fname, (parts[idx].ss |> strip) * ifelse(only_utils, " (only ext)", " (all)"))

    cb = strip(content(parts[idx]))

    #
    # Early skips: empty dbb
    #
    if isempty(cb)
        write(io, EMPTY_DBB)
        return idx
    end

    split_cb = FP.split_args(cb)
    fname    = Symbol(lowercase(first(split_cb)))
    args     = split_cb[2:end] # may be empty
    dots     = ifelse(isempty(args), "", " ...")

    #
    # DBB Processing, done in two phases:
    #   1. the external (utils-defined) functions (as they may affect context)
    #   2. the rest
    #        > A.  internal HENV (if, etc)
    #        > A'. dangling HENV (orphan else, elseif, end)
    #        > B.  e-string?
    #        > C.  hfun
    #        > D.  fill attempt / fail if unknown
    #
    #  see also `process_md_file_pass_2`
    #
    if only_utils
        if fname in utils_hfun_names(lc.glob)
            # run the function in the Utils module
            _dbb_fun(lc, io, fname, args; internal=false)
        else
            # just re-write the command for later processing
            write(io, parts[idx].ss)
        end
    else
        # A | if + variations
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

        # B | independent e-string (outside of henv)
        elseif is_estr(cb; allow_short = true)
            _dbb_fill_estr(lc, io, cb)

        # C | utils or internal function, utils have priority
        elseif (external = fname in utils_hfun_names(lc.glob)) ||
               (fname in INTERNAL_HFUNS)
            # NOTE: 
            #   the pass only_utils may already have resolved all utils-defined
            #   hfuns, unless some of those injected "order-2" double braces
            #   (not recommended...). This is why we check if fname is in utils.
            #   it should generally not happen but it might.
            #
            _dbb_fun(lc, io, fname, args; internal=!external)

        # D | fill attempt (if fail, warn+err)
        else
            _dbb_fill(lc, io, fname, args, dots)

        end
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
