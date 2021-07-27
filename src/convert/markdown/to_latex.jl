# Identical function as for html(...)

latex(md::SS,     a...; kw...) = latex(FP.default_md_partition(md; kw...), a...)
latex(md::String, a...; kw...) = latex(subs(md), a...; kw...)

function latex(parts::Vector{Block}, c::Context=DefaultLocalContext())::String
    intermediate_latex = md_core(parts, c; to_html=false)
    return latex2(intermediate_latex, c)
end

function latex(b::Block, c::Context)::String
    # early skips
    b.name == :COMMENT && return ""
    b.name in (:RAW_BLOCK, :RAW_INLINE) && return string(b.ss)
    # other blocks
    n = lowercase(String(b.name))
    f = Symbol("latex_$n")
    return eval(:($f($b, $c)))
end

recursive_latex(b, c) =
    latex(content(b), recursify(c); tokens=b.inner_tokens)
