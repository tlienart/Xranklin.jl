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

# Special rule to skip indendented blocks
struct SkipIndented end
CM.block_rule(::SkipIndented) = CM.Rule((p, c) -> 0, 8, "")
enable!(cm_parser, SkipIndented())
