"""
    html(md, ctx)

Take a markdown string, segment it in blocks, and re-form the corresponding
HTML string out of processing each segment recursively.
"""
html(md::SS,     c::Context; kw...) = html(FP.default_md_partition(md; kw...), c)
html(md::String, c::Context; kw...) = html(subs(md), c;  kw...)
html(md::String)                    = html(subs(md), DefaultLocalContext())

"""
    html(parts, ctx)

Take a partitioned markdown string, process and assemble all parts, and
finally post-process the resulting string to clear out any remaining html
blocks such as double-brace blocks.
"""
function html(parts::Vector{Block}, c::Context=cur_lc())::String
    intermediate_html = md_core(parts, c; tohtml=true)
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
function recursive_html(b::Block, c::Context)
    return recursive_html(content(b), c; tokens=b.inner_tokens)
end

function recursive_html(s::SS, c::Context; kw...)::String
    was_recursive = c.is_recursive[]
    c.is_recursive[] = true
    h = html(s, c; kw...)
    c.is_recursive[] = was_recursive
    return h
end
recursive_html(s::String, c) = recursive_html(subs(s), c)
