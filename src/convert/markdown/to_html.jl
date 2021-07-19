"""
    html(md, ctx)

Take a markdown string, segment it in blocks, and re-form the corresponding HTML string
out of processing each segment recursively.
"""
html(md::SS,     a...; kw...) = html(FP.default_md_partition(md; kw...), a...)
html(md::String, a...; kw...) = html(subs(md), a...;  kw...)

html(parts::Vector{Block}, c::Context=DefaultLocalContext())::String =
    md_core(parts, c; to_html=true)

function html(b::Block, c::Context)
    n = lowercase(String(b.name))
    f = Symbol("html_$n")
    return eval(:($f($b, $c)))
end

recursive_html(b, c) =
    html(content(b), recursify(c); tokens=b.inner_tokens)
