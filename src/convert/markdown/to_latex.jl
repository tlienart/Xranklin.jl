"""
    latex(md, ctx)

Take a markdown string, segment it in blocks, and re-form the corresponding LaTeX string
out of processing each segment recursively.
Note that, unlike HTML, we don't need to distinguish "blocks" and "inline blocks".
"""
latex(md::SS,     a...; kw...) = latex(FP.default_md_partition(md; kw...), a...)
latex(md::String, a...; kw...) = latex(subs(md), a...; kw...)

latex(parts::Vector{Block}, ctx::Context=EmptyContext())::String =
    md_core(parts, ctx; to_html=false)

function latex(b::Block, ctx::Context)
    n = lowercase(String(b.name))
    f = Symbol("latex_$n")
    return eval(:($f($b, $ctx)))
end
