"List of Blocks that should be merged with neighbouring text blocks."
const INLINE_BLOCKS = [
    :RAW_HTML,     # need to check this
    :CODE_INLINE,
    :LINEBREAK
]

#
# Everything below is logic to resolve inline insertions, and place
# `<p>..</p>` adequately (this is pretty annoying, probably best
# is to start looking at
#

const WHITESPACE_PAT = r"[^\S\n]"
const LINESKIP_PAT   = r"[^\S\n]*\n\n[^\S\n]*"
const LINESKIP_PH    = "##LINESKIP_PH##"
const INLINE_PH      = "##INLINE_PH##"
const INLINE_PAT     = Regex("$(INLINE_PH)([^\\S\\n]+)?")

const INLINE_FINDER_HTML  = Regex(
            "(</p>\\s*)?" *                  # 1 - previous closes paragraph
            "($LINESKIP_PH)?" *              # 2 - lineskip before
            "((?:$INLINE_PH[^\\S\\n]*)+)" *  # 3 - 1 or more inline placeholders
            "($LINESKIP_PH)?" *              # 4 - lineskip after
            "(\\s*<p>)?")                    # 5 - next opens p

const INLINE_FINDER_LATEX = Regex(
            "(\\\\par\\s*)?" *                # 1 - previous closes paragraph
            "($LINESKIP_PH)?" *              # 2 - lineskip before
            "((?:$INLINE_PH[^\\S\\n]*)+)" *  # 3 - 1 or more inline placeholders
            "($LINESKIP_PH)?")               # 4 - lineskip after



"""
    resolve_inline(s::String, ib::Vector{Block}, ctx::Context)

Takes a resolved HTML string and adjusts the `<p>` and `</p>` when considering inline
elements such as `<code>...</code>`. This requires a fair bit of care to keep track of
significant spaces, line skips etc; see also [`inject_with_ps`](@ref).
"""
function resolve_inline(s::String, ib::Vector{Block}, ctx::Context;
                        to_html::Bool=true)::String
    io       = IOBuffer()
    head_ib  = 1
    head_txt = 1

    inline_finder = ifelse(to_html, INLINE_FINDER_HTML, INLINE_FINDER_LATEX)
    convertor     = ifelse(to_html, html, latex)
    injector      = ifelse(to_html, html_injector, latex_injector)

    @inbounds for m in eachmatch(inline_finder, s)
        o = m.offset
        # inject text before this point
        write(io, s[head_txt:prevind(s, o)])
        # move the text head
        head_txt = nextind(s, prevind(s, o + lastindex(m.match)))

        # inline elements to inject: write each inline block in sequence
        iio = IOBuffer()
        k   = head_ib
        for im in eachmatch(INLINE_PAT, m.captures[3])
            b  = ib[k]
            write(iio, convertor(b, ctx))
            # add a space if there was one required (between inlines)
            write(iio, ifelse(im.captures[1] !== nothing, " ", ""))
            k += 1
        end
        # update the inline block head
        head_ib = k
        # form the string to inject then pass it to the final injector
        to_inject = String(take!(iio))
        injector(io, to_inject, m)
    end
    # write tail of the text
    write(io, s[head_txt:end])
    return replace(String(take!(io)), LINESKIP_PH => "\n\n")
end


function html_injector(io::IOBuffer, to_inject::String, m::RegexMatch)
    # check the match
    prev_closes_p  = (m.captures[1] !== nothing)
    prev_lineskip  = (m.captures[2] !== nothing)
    next_lineskip  = (m.captures[4] !== nothing)
    next_opens_p   = (m.captures[5] !== nothing)
    # check if there's a space to preserve before or after the injection
    space_before = ifelse(prev_closes_p && endswith(m.captures[1],   " "), " ", "")
    space_after  = ifelse(next_opens_p  && startswith(m.captures[5], " "), " ", "")
    # injector lambda
    inject(; pre="", post="") = begin
        write(io, pre, space_before, to_inject, space_after, post)
    end
    # convert the set of boolean flags into a simple "boolean string"
    case = prod(string(Int(e)) for e in
                (prev_closes_p, prev_lineskip, next_opens_p, next_lineskip))

    # There are 2^4 = 16 cases corresponding to the 16 combinations of
    # - is the previous element a text block (T</p>) or not (B)
    # - is there a line skip before (LS)
    # - is the next element a text block (<p>T) or not (B)
    # - is there a line skip after (LS)

    if     case == "0000"                   # B _ B       => B <p> _ </p> B
        inject(pre="<p>", post="</p>")
    # -------------------------------------------
    elseif case == "1000"                   # T </p> _ B  =>  T _ </p> B
        inject(post="</p>")
    elseif case == "0100"                   # B LS _ B    =>  B <p> _ </p> B
        inject(pre="<p>", post="</p>")
    elseif case == "0010"                   # B _ <p> T   =>  B <p> _ T
        inject(pre="<p>")
    elseif case == "0001"                   # B _ LS B    =>  B <p> _ </p> B
        inject(pre="<p>", post="</p>")
    # -------------------------------------------
    elseif case == "1100"                   # T </p> LS _ B   =>  T </p> <p> _ </p> B
        inject(pre="</p><p>", post="</p>")
    elseif case == "0011"                   # B _ LS <p> T    =>  B <p> _ </p> <p> T
        inject(pre="<p>", post="</p><p>")
    elseif case == "0110"                   # B LS _ <p>T     =>  B <p> _ T
        inject(pre="<p>")
    elseif case == "1001"                   # T </p> _ LS B   =>  T _ </p> B
        inject(post="</p>")
    elseif case == "1010"                   # T </p> _ <p> T  =>  T _ T
        inject()
    elseif case == "0101"                   # B LS _ LS B     =>  B <p> _ </p> B
        inject(pre="<p>", post="</p>")
    # -------------------------------------------
    elseif case == "1110"                   # T </p> LS _ <p> T  =>  T </p> <p> _ T
        inject(pre="</p><p>")
    elseif case == "0111"                   # B LS _ LS <p> T    =>  B <p> _ </p><p> T
        inject(pre="<p>", post="</p><p>")
    elseif case == "1101"                   # T </p> LS _ LS B   =>  T </p> <p> _ </p> B
        inject(pre="</p><p>", post="</p>")
    elseif case == "1011"                   # T </p> _ LS <p>T   =>  T _ </p> <p> T
        inject(post="</p><p>")
    # -------------------------------------------
    elseif case == "1111"                   # T </p> LS _ LS <p> T  =>  T </p> <p> _ </p> <p> T
        inject(pre="</p><p>", post="</p><p>")
    end
end


function latex_injector(io::IOBuffer, to_inject::String, m::RegexMatch)
    # check the match
    prev_closes_p  = (m.captures[1] !== nothing)
    prev_lineskip  = (m.captures[2] !== nothing)
    next_lineskip  = (m.captures[4] !== nothing)
    # check if there's a space to preserve before or after the injection
    space_before = ifelse(prev_closes_p && endswith(m.captures[1],   " "), " ", "")
    # injector lambda
    inject(; pre="", post="") = begin
        write(io, pre, space_before, to_inject, post)
    end
    # convert the set of boolean flags into a simple "boolean string"
    case = prod(string(Int(e)) for e in
                (prev_closes_p, prev_lineskip, next_lineskip))

    # There are 2^3 = 8 cases corresponding to the combinations
    LS = "\n\n"
    if     case == "000"    # B _ B => B _ B
        inject()
    # -------------------------------------------
    elseif case == "100"    # T \par _ B  =>  T _ \par B
        inject()
    elseif case == "010"    # B LS _ B    =>  B LS _ B
        inject(pre=LS)
    elseif case == "001"    # B _ LS B    =>  B _ LS B
        inject(post=LS)
    # -------------------------------------------
    elseif case == "110"    # T \par LS _ B  =>  T LS _ B
        inject(pre=LS)
    elseif case == "101"    # T \par _ LS B  =>  T _ LS B
        inject(post=LS)
    elseif case == "011"    # B LS _ LS B    =>  B LS _ LS B
        inject(pre=LS, post=LS)
    # -------------------------------------------
    elseif case == "111"    # T \par LS _ LS B  => T LS _ LS B
        inject(pre=LS, post=LS)
    end
    return
end

@inline raw_block(b::Block) = Block(:RAW, b.ss)
