"""
    md2html(s::String)

Wrapper around what CommonMark does to keep track of spaces etc which CM strips away but
which are actually needed in order to adequately resolve inline inserts.
"""
function md2html(s::String)::String
    isempty(s) && return ""
    r = CM.html(cm_parser(s))
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
    html(md, ctx)

Take a markdown string, segment it in blocks, and re-form the corresponding HTML string
out of processing each segment recursively.
"""
html(md::SS,     a...) = html(FP.default_md_partition(md), a...)
html(md::String, a...) = html(subs(md), a...)

function html(parts::Vector{Block}, ctx::Context=EmptyContext())::String
    process_latex_objects!(parts, ctx)
    io = IOBuffer()
    inline_idx = Int[]
    for (i, part) in enumerate(parts)
        if part.name in INLINE_BLOCKS
            write(io, INLINE_PH)
            push!(inline_idx, i)
        else
            write(io, html(part, ctx))
        end
    end
    interm = String(take!(io))
    return resolve_inline(interm, parts[inline_idx], ctx; to_html=true)
end

function html(b::Block, ctx::Context)
    n = lowercase(String(b.name))
    f = Symbol("html_$n")
    return eval(:($f($b, $ctx)))
end
