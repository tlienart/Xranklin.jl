"""
    math(md, ctx)

Take a markdown string in a math context, segment it in blocks, and re-form the
corresponding raw md-math string out of processing each segment recursively.
"""
math(md::SS,     c::LocalContext; kw...) = math(FP.default_math_partition(md), c; kw...)
math(md::String, c::LocalContext; kw...) = math(subs(md), c; kw...)
math(b::Block,   c::LocalContext; kw...) = math(content(b), c; kw...)

function math(parts::Vector{Block}, c::LocalContext; tohtml::Bool=true)::String
    c.is_recursive[] = c.is_math[] = true
    process_latex_objects!(parts, c; tohtml)
    c.is_recursive[] = c.is_math[] = false
    io = IOBuffer()
    for (i, part) in enumerate(parts)
        write(io, part.ss)
    end
    return String(take!(io))
end


"""
    dmath

Display math block on a page with HTML output and processing of possible
label command. If a label command is found, the output is preceded with an
anchor.
"""
function dmath(b::Block, c::LocalContext)
    md = string(content(b))
    # check if there's a \label{...}, if there is, process it
    # then remove it & do the rest of the processing
    anchor = ""
    label_match = match(MATH_LABEL_PAT, md)
    if label_match !== nothing
        id     = string_to_anchor(string(label_match.captures[1]))
        class  = getvar(c, :anchor_class, "anchor") * " " *
                 getvar(c, :anchor_math_class, "anchor-math")
        anchor = html_a(; id, class)
        md     = replace(md, MATH_LABEL_PAT => "")
        # keep track of the reference + numbering
        eqrefs(c)[id] = (eqrefs(c)["__cntr__"] += 1)
    end
    return "$anchor\\[ $(math(FP.default_math_partition(md), c)) \\]\n"
end
