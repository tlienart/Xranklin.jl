const EMPTY_DBB = "__EMPTY_DBB__"

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

function html2(
            parts::Vector{Block},
            c::Context
        )::String

    crumbs(@fname)

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

        if b.name != :DBB
            if b.name == :TEXT
                write(io, string(b.ss))
            elseif b.name == :SCRIPT
                if getvar(cgc, :parse_script_blocks, true)
                    write(io, html2(string(b.ss), c; disable=[:SCRIPT_OPEN, :SCRIPT_CLOSE]))
                else
                    write(io, string(b.ss))
                end
            elseif b.name in (:MATH_INLINE, :MATH_BLOCK)
                # do not reprocess what's inside, so, specifically, if there's a double
                # brace block within a math context, it will be ignored, this prevents
                # errors where you'd have math with {{ and or }}
                write(io, string(b.ss))
            end
            continue
        end

        # -----------------------------
        # Double Brace Block processing
        # -----------------------------
        cb = strip(content(b))

        # empty double brace -> write as empty (will be reconsidered at the end
        # as part of the EMPTY_DBB processing)
        if isempty(cb)
            write(io, EMPTY_DBB)

        # e-string fill
        elseif is_estr(cb; allow_short=true)
            v = eval_str(cb)
            if isa(v, EvalStrError)
                @warn """
                    {{ e"..." }} or {{ > ... }}
                    ---------------------------
                    An environment '{{ e"..." }}' failed to evaluate properly,
                    check that the code in the e-string is valid and that
                    variables are prefixed with a \$.
                    """
                write(io, hfun_failed([cb |> string]))
            else
                sv = string(v)
                if isempty(sv)
                    write(io, EMPTY_DBB)
                else
                    write(io, sv)
                end
            end

        # Other cases:
        # A. internal HENV (if, and derived like ispage, for)
        # A'. orphan elseif/else/end
        # B. internal or external HFUNS
        # C. fill attempt
        # ---------------------------------------------------
        else
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

            # A' found a dangling {{elseif}} or {{else}} or whatever
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
                mdl   = ifelse(u, cgc.nb_code.mdl, @__MODULE__)
                args  = split_cb[2:end]
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
                set_current_global_context(cgc)
                clc === nothing || set_current_local_context(clc)

            # C - try fill
            else
                # try to see if it could be an implicit fill {{vname}}
                fs = ""
                fill_failed = false

                if length(split_cb) == 1
                    # Fill from LC
                    if clc !== nothing && ((v = getvar(clc, fname)) !== nothing)
                        fs = string(v)

                    # Fill from GC
                    elseif ((v = getvar(cgc, fname)) !== nothing)
                        fs = string(v)

                    # Fill from Utils
                    elseif fname in utils_var_names()
                        mdl = cgc.nb_code.mdl
                        fs  = getproperty(mdl, fname) |> string

                    else
                        fill_failed = true
                    end
                else
                    fill_failed = true
                end

                if fill_failed
                    @warn """
                      {{ ... }}
                      ---------
                      A block '{{$fname ...}}' was found but the name '$fname'
                      does not correspond to a built-in block or hfun nor does
                      it match anything defined in `utils.jl`. It might have
                      been misspelled.
                      """
                    fs = hfun_failed(split_cb)
                end

                if isempty(fs)
                    write(io, EMPTY_DBB)
                else
                    write(io, fs)
                end
            end
        end # end dbb
    end
    out = String(take!(io))
    out = replace(out, Regex("(?:<p>\\s*$(EMPTY_DBB)\\s*</p>)|(?:$(EMPTY_DBB))") => "")
    return out
end
