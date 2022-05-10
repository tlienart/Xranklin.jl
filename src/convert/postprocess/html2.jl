"""
    html2(s, lc; only)

Postprocess a html string `s` in the local context `lc` (e.g. find and process
double brace blocks).

## Notes on resolving hfun

* case doesn't matter (so `{{FOO}}` is the same as `{{fOo}}` etc)
* globvar `parse_script_blocks` whether to parse `{{...}}` blocks in <script>
   blocks or not.

"""
function html2(
            parts::Vector{Block},
            lc::LocalContext;
            only::Vector{Symbol}=Symbol[]
        )::String

    crumbs(@fname)

    gc     = lc.glob
    io     = IOBuffer()
    idx    = 0
    nparts = length(parts)

    while idx < nparts
        idx += 1
        b    = parts[idx]

        # non DBB blocks
        if b.name != :DBB
            if b.name == :TEXT
                write(io, string(b.ss))

            elseif b.name == :SCRIPT
                if getvar(gc, :parse_script_blocks, true)
                    tw = html2(
                            string(b.ss), lc;
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

        # DBB blocks
        else
            idx = resolve_dbb(io, parts, idx, lc; only)

        end
    end # end while

    out = String(take!(io))
    out = replace(out, EMPTY_DBB_PAT => "")
    return out
end

function html2(
            s::String,
            lc::LocalContext;
            only=Symbol[],
            kw...           # kw for the partitioning
        )

    parts = FP.html_partition(s; kw...)
    return html2(parts, lc; only)
end
