# """
#     html(md, ctx)
#
# Take a markdown string, segment it in groups of blocks, and re-form the
# corresponding HTML string out of processing each segment recursively.
#
# ## KwArgs
#
#     * disable: vector of Symbol, allows to ignore tokens like MATH_A or RAW.
# """
# html(md::SS, c::Context; kw...) =
#     html(FP.md_partition(md; kw...) |> FP.md_grouper, c)
#
# html(md::String, c::Context; kw...) = html(subs(md), c;  kw...)
# html(md::String)                    = html(subs(md), DefaultLocalContext())
#
# """
#     html(groups, ctx)
#
# Take a partitioned markdown string, process and assemble all parts, and
# finally post-process the resulting string to clear out any remaining html
# blocks such as double-brace blocks.
# """

# function html(md, c::Context=cur_lc(); kw...)::String
#     intermediate_html = convert_md(md, c; kw...)
#     return html2(intermediate_html, c)
# end

"""
    html(block, ctx)

Take a markdown block and process it to return the corresponding html in the
given context by applying the rule relevant to that block.
"""
function html(b::Block, c::Context)::String
    # early skips
    b.name == :RAW && return string(content(b))
    b.name == :COMMENT && return " "
    b.name in (:RAW_BLOCK, :RAW_INLINE) && return string(b.ss)
    # other blocks
    n = lowercase(String(b.name))
    f = Symbol("html_$n")
    return eval(:($f($b, $c)))
end

"""
    rhtml

Same as html but marking the context as recursive.
"""
function rhtml(s::SS, c::Context; kw...)::String
    was_recursive = c.is_recursive[]
    c.is_recursive[] = true
    h = html(s, c; kw...)
    c.is_recursive[] = was_recursive
    return h
end
rhtml(s::String, c; kw...) = rhtml(subs(s), c; kw...)
rhtml(b::Block, c; kw...)  = rhtml(content(b), c; tokens=b.inner_tokens, kw...)
