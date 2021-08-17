cm_parser = CM.Parser()

# Enable and disable block rules depending on whether Franklin processes
# them or whether it should be CommonMark.

# >> Block Defaults
enable!(cm_parser, CM.TableRule())
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


# Special rule to skip indendented blocks
struct SkipIndented end
CM.block_rule(::SkipIndented) = CM.Rule((p, c) -> 0, 8, "")
enable!(cm_parser, SkipIndented())


"""
    md2x(s::String, tohtml::Bool)

Wrapper around what CommonMark does to keep track of spaces etc which CM
strips away but which are actually needed in order to adequately resolve
inline inserts. Leads to either html or latex based on the case.
"""
function md2x(s::String, tohtml::Bool)::String
    isempty(s) && return ""
    if tohtml
        r = CM.html(cm_parser(s))
    else
        r = CM.latex(cm_parser(s))
    end
    # if there was only r"\s*" in s, preserve that unless it's a lineskip
    if isempty(r)
        return ifelse(occursin("\n\n", s), LINESKIP_PH, s)
    end
    # check if the block is preceded or followed by a lineskip (\n\n)
    # or, by a space that we might have to preserve (e.g. inline)
    # if that's the case, either inject an indicator or a space
    pre  = ""
    post = ""
    if startswith(s, LINESKIP_PAT)
        pre = LINESKIP_PH
    elseif startswith(s, WHITESPACE_PAT)
        pre = " "
    end
    if endswith(s, LINESKIP_PAT)
        post = LINESKIP_PH
    elseif endswith(s, WHITESPACE_PAT)
        post = " "
    end
    return pre * r * post
end

md2html(s::String)  = md2x(s, true)
md2latex(s::String) = md2x(s, false)


"""
    md_core(parts, ctx; tohtml)

Function processing blocks in sequence and assembling them while resolving
possible balancing issues.
"""
function md_core(
            parts::Vector{Block},
            c::Context;
            tohtml::Bool=true
            )::String

    transformer = ifelse(tohtml, html, latex)
    process_latex_objects!(parts, c; tohtml)

    io = IOBuffer()
    inline_idx = Int[]
    for (i, part) in enumerate(parts)
        if part.name in INLINE_BLOCKS
            write(io, INLINE_PH)
            push!(inline_idx, i)
        else
            write(io, transformer(part, c))
        end
    end
    interm = String(take!(io))
    return resolve_inline(interm, parts[inline_idx], c, tohtml)
end
