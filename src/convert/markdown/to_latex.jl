# Identical function as for html(...)

latex(md::SS,     a...; kw...) = latex(FP.md_partition(md; kw...), a...)
latex(md::String, a...; kw...) = latex(subs(md), a...; kw...)
latex(md::String)              = latex(subs(md), DefaultLocalContext())

function latex(parts::Vector{Block}, c::Context=cur_lc())::String
    intermediate_latex = md_core(parts, c; tohtml=false)
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

function rlatex(b::Block, c::Context)
    return rlatex(content(b), c; tokens=b.inner_tokens)
end
function rlatex(s::SS, c::Context; kw...)::String
    was_recursive = c.is_recursive[]
    c.is_recursive[] = true
    l = latex(s, c; kw...)
    c.is_recursive[] = was_recursive
    return l
end
rlatex(s::String, c) = rlatex(subs(s), c)
