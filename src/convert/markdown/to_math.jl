"""
    math(md, ctx)

Take a markdown string in a math context, segment it in blocks, and re-form the
corresponding raw md-math string out of processing each segment recursively.
"""
math(md::SS,     c::LocalContext) = math(FP.default_math_partition(md), c)
math(md::String, c::LocalContext) = math(subs(md), c)
math(b::Block,   c::LocalContext) = math(content(b), c)

function math(parts::Vector{Block}, c::LocalContext)::String
    process_latex_objects!(parts, mathify(c); recursion=math)
    io = IOBuffer()
    for (i, part) in enumerate(parts)
        write(io, part.ss)
    end
    return String(take!(io))
end
