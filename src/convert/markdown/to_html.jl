"""
    html(md, ctx)

Take a markdown string, segment it in blocks, and re-form the corresponding
HTML string out of processing each segment recursively.
"""
html(md::SS,     a...; kw...) = html(FP.default_md_partition(md; kw...), a...)
html(md::String, a...; kw...) = html(subs(md), a...;  kw...)

"""
    html(parts, ctx)

Take a partitioned markdown string, process and assemble all parts, and
finally post-process the resulting string to clear out any remaining html
blocks such as double-brace blocks.
"""
function html(parts::Vector{Block}, c::Context=DefaultLocalContext())::String
    intermediate_html = md_core(parts, c; to_html=true)
    return html2(intermediate_html, c)
end

"""
    html(block, ctx)

Take a markdown block and process it to return the corresponding html in the
given context by applying the rule relevant to that block.
"""
function html(b::Block, c::Context)::String
    # early skips
    b.name == :COMMENT && return ""
    b.name in (:RAW_BLOCK, :RAW_INLINE) && return string(b.ss)
    # other blocks
    n = lowercase(String(b.name))
    f = Symbol("html_$n")
    return eval(:($f($b, $c)))
end

"""
    recursive(b, c)

Recursively process a block making the context recursive.
"""
recursive_html(b::Block, c::Context)::String =
    html(content(b), recursify(c); tokens=b.inner_tokens)
