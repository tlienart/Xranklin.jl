"""
    math(md, ctx)

Take a markdown string in a math context, segment it in blocks, and re-form the
corresponding raw md-math string out of processing each segment recursively.
"""
math(md::SS, c::Context)     = math(FP.default_math_partition(md), c)
math(md::String, c::Context) = math(subs(md), c)
math(b::Block, c::Context)   = math(content(b), c)

function math(parts::Vector{Block}, ctx::Context)::String
    process_latex_objects!(parts, mathify(ctx); recursion=math)
    io = IOBuffer()
    for (i, part) in enumerate(parts)
        write(io, part.ss)
    end
    return String(take!(io))
end
