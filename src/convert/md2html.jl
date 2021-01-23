#
# CommonMark setup
#
# Disable indentation rule (we don't allow indented block as code block)
# see https://github.com/MichaelHatherly/CommonMark.jl/issues/1#issuecomment-735990126)
# struct SkipIndented end
#
# block_rule(::SkipIndented) = CM.Rule((p, c) -> 0, 8, "")
#
# cm_parser = CM.enable!(
#                 CM.disable!(
#                     CM.Parser(),
#                     CM.IndentedCodeBlockRule()),
#                 SkipIndented())

cm_parser = CM.Parser()

# Enable and disable block rules depending on whether Franklin takes them
# or CM.

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

struct SkipIndented end
CM.block_rule(::SkipIndented) = CM.Rule((p, c) -> 0, 8, "")
enable!(cm_parser, SkipIndented())


md2html(s::String)  = CM.html(cm_parser(s))
md2latex(s::String) = CM.latex(cm_parser(s))

# ------------------------------------------------------------------------

function html(parts::Vector{Block}, ctx::Context=EmptyContext)::String
    io = IOBuffer()
    for part in parts
        write(io, html(part, ctx))
    end
    return String(take!(io))
end

html(md::String, a...) = html(default_md_partition(md), a...)
