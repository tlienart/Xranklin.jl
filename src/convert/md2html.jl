md2html(s::String)  = CM.html(cm_parser(s))

"""List of Blocks that should be merged with neighbouring text blocks."""
const INLINE_BLOCKS = [
    :RAW_HTML,     # need to check this
    :CODE_INLINE,
    :LINEBREAK
]
@inline isinline(b::Block) = (b.name in INLINE_BLOCKS)

const INLINE_PH = "##INLINE_PH##"
const INLINE_PH_N = length(INLINE_PH)
const INLINE_PH_FINDER = Regex("(</p>[\\n\\s]*)?((?:$(INLINE_PH))+)([\\n\\s]*<p>)?")

"""
$SIGNATURES

Take a markdown string, segment it in blocks, and re-form the corresponding HTML string
out of processing each segment recursively.
"""
html(md::SS, a...) = html(FP.default_md_partition(md), a...)

html(md::String, a...) = html(subs(md), a...)

function html(parts::Vector{Block}, ctx::Context=EmptyContext)::String
    io = IOBuffer()
    # list of indices corresponding to inline blocks
    inline_idx = Int[]
    for (i, part) in enumerate(parts)
        if part.name in INLINE_BLOCKS
            # write a placeholder which will be replaced by `resolve_inline`
            write(io, INLINE_PH)
            push!(inline_idx, i)
        else
            write(io, html(part, ctx))
        end
    end
    interm = String(take!(io))
    return resolve_inline(interm, parts[inline_idx], ctx)
end

function html(b::Block, c::Context)
    n = lowercase(String(b.name))
    f = Symbol("html_$n")
    return eval(:($f($b, $c)))
end

const PARAGRAPH_GAP = ['\n', '\n']

"""
$SIGNATURES

Takes a resolved HTML string and adjusts the `<p>` and `</p>` when considering inline
elements such as `<code>...</code>`.
"""
function resolve_inline(s::String, ib::Vector{Block}, ctx::Context)::String
    io = IOBuffer()
    head = 1
    head_txt = 1
    @inbounds for m in eachmatch(INLINE_PH_FINDER, s)
        o = m.offset
        # head text to inject
        write(io, s[head_txt:prevind(s, o)])
        head_txt = nextind(s, prevind(s, o + lastindex(m.match)))

        # check the match
        prev_closes_p   = (m.captures[1] !== nothing)  # </p> INLINE
        n_inline_blocks = Int(length(m.captures[2]::SS) / INLINE_PH_N)
        next_opens_p    = (m.captures[3] !== nothing)   # INLINE <p>

        # inline html to inject
        to_inject = prod(html(e, ctx) for e in ib[head:head+n_inline_blocks-1])

        curb  = ib[head]
        nextb = ib[head+n_inline_blocks-1]
        head  = head + n_inline_blocks

        prev_closes_p &= (FP.previous_chars(curb, 2) != PARAGRAPH_GAP)
        next_opens_p  &= (FP.next_chars(nextb, 2) != PARAGRAPH_GAP)

        # adjust the ps depending on the case
        if !xor(prev_closes_p, next_opens_p)
            write(io, to_inject)
        elseif prev_closes_p
            write(io, to_inject * "</p>")
        else # next_opens_p
            write(io, "<p>" * to_inject)
        end
    end
    write(io, s[head_txt:end])
    return String(take!(io))
end
