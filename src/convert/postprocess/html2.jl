"""
    html2(s, c)

Postprocess a html string `s` in the context `c` (e.g. find and process double
brace blocks).

## Notes on resolving hfun

* case doesn't matter (so `{{FOO}}` is the same as `{{fOo}}` etc)
* globvar `parse_script_blocks` whether to parse `{{...}}` blocks in <script>
   blocks or not.

## Errors (see XXX)
"""
html2(s::String, c::Context; kw...) = html2(FP.html_partition(s; kw...), c)

function html2(parts::Vector{Block}, c::Context)::String
    crumbs("html2")
    # DEV NOTES
    # ---------
    # * since the hfuns might call a process_file function which, itself
    # sets a cur_local_ctx, it's important to re-set the cur_local_ctx after
    # calling any hfun.
    # -----------------------------------------------------------------
    # Keep track of the current gc and lc, these may be changed
    # by the call to hfuns but should be re-set afterwards
    # we use the direct `env/setenv` for local since it may be nothing!
    cgc = cur_gc()
    clc = env(:cur_local_ctx)

    io     = IOBuffer()
    idx    = 0
    nparts = length(parts)
    while idx < nparts
        idx += 1
        b    = parts[idx]

        if b.name == :COMMENT
            continue
        elseif b.name == :TEXT
            write(io, string(b.ss))
            continue
        elseif b.name == :SCRIPT
            if getvar(cgc, :parse_script_blocks, true)
                write(io, html2(string(b.ss), c; disable=[:SCRIPT_OPEN,  :SCRIPT_CLOSE]))
            else
                write(io, string(b.ss))
            end
            continue
        end

        # -----------------------------
        # Double Brace Block processing
        # A. internal HCOND (if, and derived like ispage)
        # B. internal HFOR  (for)
        # C. orphan elseif/else/end
        # D. internal HFUNS (fill, insert, ...) or external ones
        # E. default to fill attempt

        cb = strip(content(b))
        isempty(cb) && continue
        split_cb = FP.split_args(cb)
        fname    = Symbol(lowercase(first(split_cb)))

        # A - internal HENV
        if fname in INTERNAL_HENVS
            henv, ci = find_henv(parts, idx)

            if isempty(henv)
                @warn """
                    {{ $fname ... }}
                    ----------------
                    An environment '{{$fname ...}}' was not closed properly.
                    """
                write(io, hfun_failed(split_cb))
            end
            resolve_henv(henv, io, c)
            idx = ci

        # found a dangling {{elseif}} or {{else}} or whatever
        elseif fname in INTERNAL_HORPHAN
            @warn """
                {{ $fname ... }}
                ----------------
                A block '{{$fname ...}}' was found out of a relevant context.
                """
            write(io, hfun_failed(split_cb))

        # B - internal or external HFUNS
        elseif (u = fname in utils_hfun_names()) || fname in INTERNAL_HFUNS
            # 'external' functions defined with `hfun_*`, they
            # take precedence so a user can overwrite the behaviour of
            # internal functions
            mdl = ifelse(u, cgc.nb_code.mdl, @__MODULE__)
            args  = split_cb[2:end]
            fsymb = Symbol("hfun_$fname")
            f     = getproperty(mdl, fsymb)
            write(io, outputof(f, args; tohtml=true))

            # re-set current local and global context, just in case these were
            # changed by the call to the hfun (e.g. by triggering a processing)
            set_current_global_context(cgc)
            clc === nothing || set_current_local_context(clc)

        # C - try fill
        else
            # try to see if it could be an implicit fill {{vname}}
            if (length(split_cb) == 1) && ((v = getvar(clc, fname)) !== nothing)
                write(io, string(v))
            elseif (length(split_cb) == 1) && (fname in utils_var_names())
                mdl = cgc.nb_code.mdl
                write(io, string(getproperty(mdl, fname)))
            else
                @warn """
                    {{ ... }}
                    ---------
                    A block '{{$fname ...}}' was found but the name '$fname'
                    does not correspond to a built-in block or hfun nor does it
                    match anything defined in `utils.jl`. It might have been
                    misspelled.
                    """
                write(io, hfun_failed(split_cb))
            end
        end
    end
    return String(take!(io))
end
