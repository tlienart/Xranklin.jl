# --------------------------------------------------------------------------------------
# CommonMark setup
cm_parser = CM.Parser()
# Enable and disable block rules depending on whether Franklin processes
# them or whether it should be CommonMark.
# >> Block Defaults
disable!(cm_parser, CM.AtxHeadingRule())         # ### headings
# -- BlockQuoteRule()
disable!(cm_parser, CM.FencedCodeBlockRule())
disable!(cm_parser, CM.HtmlBlockRule())
disable!(cm_parser, CM.IndentedCodeBlockRule())  # no indented, see skip indented
# -- ListItemRule()
disable!(cm_parser, CM.SetextHeadingRule())      # headings with '---' --> use ATX
disable!(cm_parser, CM.ThematicBreakRule())      # horizontal rules
# >> Inline Defaults
# -- AsteriskEmphasisRule()
# -- AutolinkRule()
# -- HtmlEntityRule()
disable!(cm_parser, CM.HtmlInlineRule())
# -- ImageRule()
disable!(cm_parser, CM.InlineCodeRule())
# -- LinkRule()
# -- UnderscoreEmphasisRule()
# --------------------------------------------------------------------------------------
struct SkipIndented end
CM.block_rule(::SkipIndented) = CM.Rule((p, c) -> 0, 8, "")
enable!(cm_parser, SkipIndented())
# --------------------------------------------------------------------------------------

md2html(s::String)  = CM.html(cm_parser(s))
md2latex(s::String) = CM.latex(cm_parser(s))

# ------------------------------------------------------------------------
"""List of Blocks that should be merged with neighbouring text blocks."""
const INLINE_BLOCKS = [
    :RAW_HTML,     # need to check this
    :CODE_INLINE,
    :LINEBREAK
]
@inline isinline(b::Block) = (b.name in INLINE_BLOCKS)

const INLINE_PH = "##INLINE_PH##"
const INLINE_PH_N = length(INLINE_PH)
const INLINE_PH_FINDER = Regex("(</p>[\\n\\s]*)?($(INLINE_PH))+([\\n\\s]*<p>)?")

function html(parts::Vector{Block}, ctx::Context=EmptyContext)::String
    io = IOBuffer()
    inline_idx = Int[]
    for (i, part) in enumerate(parts)
        if part.name in INLINE_BLOCKS
            write(io, INLINE_PH)
            push!(inline_idx, i)
        else
            write(io, html(part, ctx))
        end
    end
    return resolve_inline(String(take!(io)), parts[inline_idx], ctx)
end

html(md::String, a...) = html(FP.default_md_partition(md), a...)


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
        head      = head + n_inline_blocks

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
