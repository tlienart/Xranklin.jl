"""
    html(block, ctx)

Take a markdown block and process it to return the corresponding html in the
given context by applying the rule relevant to that block.
"""
function html(b::Block, c::Context)::String
    # early skips
    if b.name == :RAW
        return string(content(b))
    elseif b.name == :COMMENT
        return " "
    elseif b.name in (:RAW_BLOCK, :RAW_INLINE)
        return string(b.ss)
    end
    # other blocks
    n = lowercase(String(b.name))
    f = Symbol("html_$n")
    return eval(:($f($b, $c)))
end

"""
    rhtml

Same as html but marking the context as recursive.
"""
function rhtml(s::SS, c::Context; kw...)::String
    was_recursive = c.is_recursive[]
    c.is_recursive[] = true
    h = html(s, c; kw...)
    c.is_recursive[] = was_recursive
    return h
end
rhtml(s::String, c; kw...) = rhtml(subs(s), c; kw...)
rhtml(b::Block, c; kw...)  = rhtml(content(b), c; tokens=b.inner_tokens, kw...)
