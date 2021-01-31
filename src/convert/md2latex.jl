md2latex(s::String) = CM.latex(cm_parser(s))

"""
$SIGNATURES

Take a markdown string, segment it in blocks, and re-form the corresponding LaTeX string
out of processing each segment recursively.
Note that, unlike HTML, we don't need to distinguish "blocks" and "inline blocks".
"""
latex(md::String, a...) = latex(FP.default_md_partition(md), a...)

function latex(parts::Vector{Block}, ctx::Context=EmptyContext)::String
    io = IOBuffer()
    for part in parts
        write(io, latex(part, ctx))
    end
    return String(take!(io))
end

function latex(b::Block, c::Context)
    n = lowercase(String(b.name))
    f = Symbol("latex_$n")
    return eval(:($f($b, $c)))
end
