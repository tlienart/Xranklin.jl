"""
    md2latex(s::String)

Wrapper around what CommonMark does to keep track of spaces etc which CM strips away but
which are actually needed in order to adequately resolve inline inserts.
"""
function md2latex(s::String)::String
    isempty(s) && return ""
    r = CM.latex(cm_parser(s))
    # if there was only r"\s" in s, preserve that
    isempty(r) && return s
    # check if the block is preceded or followed by a lineskip (\n\n)
    # or, by a space that we might have to preserve (e.g. inline)
    # if that's the case, either inject an indicator or a space
    pre  = ""
    post = ""
    if startswith(s, LINESKIP_PAT)
        pre = LINESKIP_PH
    elseif startswith(s, WHITESPACE_PAT)
        pre = " "
    end
    if endswith(s, LINESKIP_PAT)
        post = LINESKIP_PH
    elseif endswith(s, WHITESPACE_PAT)
        post = " "
    end
    return pre * r * post
end


"""
    latex(md, ctx)

Take a markdown string, segment it in blocks, and re-form the corresponding LaTeX string
out of processing each segment recursively.
Note that, unlike HTML, we don't need to distinguish "blocks" and "inline blocks".
"""
latex(md::SS,     a...; kw...) = latex(FP.default_md_partition(md; kw...), a...)
latex(md::String, a...; kw...) = latex(subs(md), a...; kw...)

function latex(parts::Vector{Block}, ctx::Context=EmptyContext())::String
    process_latex_objects!(parts, ctx; recursion=latex)
    io = IOBuffer()
    inline_idx = Int[]
    for (i, part) in enumerate(parts)
        if part.name in INLINE_BLOCKS
            write(io, INLINE_PH)
            push!(inline_idx, i)
        else
            write(io, latex(part, ctx))
        end
    end
    interm = String(take!(io))
    return resolve_inline(interm, parts[inline_idx], ctx; to_html=false)
end

function latex(b::Block, ctx::Context)
    n = lowercase(String(b.name))
    f = Symbol("latex_$n")
    return eval(:($f($b, $ctx)))
end
