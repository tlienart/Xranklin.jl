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
html2(s::String, c::Context; only=Symbol[], kw...) = html2(FP.html_partition(s; kw...), c; only)

function html2(
            parts::Vector{Block},
            c::Context;
            only::Vector{Symbol}=Symbol[]
        )::String

    crumbs(@fname)

    # DEV NOTES
    # ---------
    # * since the hfuns might call a process_file function which, itself
    # sets a cur_local_ctx, it's important to re-set the cur_local_ctx after
    # calling any hfun. So here we keep track of the current gc/lc as
    # these may change, and re-set those at the end.
    if c isa GlobalContext
        cgc = c
        clc = env(:cur_local_ctx)  # May be nothing
    else
        cgc = c.glob
        clc = c
    end

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
                    tw = html2(
                        string(b.ss), c;
                        disable=[:SCRIPT_OPEN, :SCRIPT_CLOSE]
                    )
                    write(io, tw)
                else
                    write(io, string(b.ss))
                end
            elseif b.name in (:MATH_INLINE, :MATH_BLOCK)
                # do not reprocess what's inside, so, specifically, if there's a double
                # brace block within a math context, it will be ignored, this prevents
                # errors where you'd have math with {{ and or }}
                write(io, string(b.ss))
            end
        else
            idx = resolve_dbb(io, parts, idx, c, cgc, clc; only)
        end
    end # end while
    out = String(take!(io))
    out = replace(out, EMPTY_DBB_PAT => "")
    return out
end
