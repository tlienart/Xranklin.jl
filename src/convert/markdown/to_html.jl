"""
    html(md, ctx)

Take a markdown string, segment it in blocks, and re-form the corresponding HTML string
out of processing each segment recursively.
"""
html(md::SS,     a...; kw...) = html(FP.default_md_partition(md; kw...), a...)
html(md::String, a...; kw...) = html(subs(md), a...;  kw...)

html(parts::Vector{Block}, ctx::Context=EmptyContext())::String =
    md_core(parts, ctx; to_html=true)

function html(b::Block, ctx::Context)
    n = lowercase(String(b.name))
    f = Symbol("html_$n")
    return eval(:($f($b, $ctx)))
end
