# Identical function as for html(...)

latex(md::SS,     a...; kw...) = latex(FP.default_md_partition(md; kw...), a...)
latex(md::String, a...; kw...) = latex(subs(md), a...; kw...)

function latex(parts::Vector{Block}, c=cur_lc())::String
    c === nothing && (c = DefaultLocalContext())
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

function recursive_latex(b::Block, c::Context)
    return recursive_latex(content(b), c; tokens=b.inner_tokens)
end
function recursive_latex(s::SS, c::Context; kw...)::String
    was_recursive = c.is_recursive[]
    c.is_recursive[] = true
    l = latex(s, c; kw...)
    c.is_recursive[] = was_recursive
    return l
end
recursive_latex(s::String, c) = recursive_latex(subs(s), c)
