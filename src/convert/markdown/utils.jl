"""
    raw_block(b)

Form a raw block out of a block, the content of raw blocks is injected as is
(without tags surrounding it). This is for instance used in the processing of
latex objects when resolving commands.
"""
@inline raw_inline_block(b::Block) = Block(:RAW_INLINE, b.ss)


"""
    INLINE_BLOCKS

List of Blocks that should be merged with neighbouring text blocks.
Note: a COMMENT is not one of those (it always splits).
"""
const INLINE_BLOCKS = [
    :RAW_INLINE,
    :RAW_HTML,
    :CODE_INLINE,
    :LINEBREAK,
    :MATH_A,
    :MATH_I,
    :DBB
]

#
# Everything below is logic to resolve inline insertions, and place
# `<p>..</p>` adequately (this is pretty annoying).
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
            "(\\\\par\\s*)?" *               # 1 - previous closes paragraph
            "($LINESKIP_PH)?" *              # 2 - lineskip before
            "((?:$INLINE_PH[^\\S\\n]*)+)" *  # 3 - 1 or more inline placeholders
            "($LINESKIP_PH)?")               # 4 - lineskip after


"""
    resolve_inline(s::String, ib::Vector{Block}, ctx::LocalContext)

Takes a resolved HTML or LaTeX string and rewrites a string after inserting
inline blocks while adjusting the paragraph tags (`<p>`, `</p>`, `\\par`)
appropriately.
This unfortunately requires a fair bit of care to keep track of significant
spaces, line skips etc.
"""
function resolve_inline(
            s::String,
            ib::Vector{Block},
            ctx::Context,
            to_html::Bool=true
            )::String

    # io is the buffer for the resulting 'injected' string
    io       = IOBuffer()
    head_ib  = 1
    head_txt = 1

    inline_finder = ifelse(to_html, INLINE_FINDER_HTML, INLINE_FINDER_LATEX)
    convertor     = ifelse(to_html, html, latex)

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
        paragraph_injector!(io, to_inject, m; to_html=to_html)
    end
    # write tail of the text
    write(io, s[head_txt:end])
    return replace(String(take!(io)), LINESKIP_PH => "\n\n")
end


"""
    check_case(m)

Check what kind of situation we're in to figure out how to merge blocks.
"""
function check_case(m::RegexMatch, to_html::Bool=true)::NTuple{3,String}
    prev_closes_p = (m.captures[1] !== nothing)
    prev_lineskip = (m.captures[2] !== nothing)
    next_lineskip = (m.captures[4] !== nothing)
    next_opens_p  = to_html ? (m.captures[5] !== nothing) : true

    # check if there's a space to preserve before or after the injection
    space_before = ifelse(
        prev_closes_p && endswith(m.captures[1],   " "),
        " ", ""
    )
    space_after  = ifelse(
        to_html && next_opens_p && startswith(m.captures[5], " "),
        " ", ""
    )

    # convert the set of boolean flags into a simple "boolean string"
    case = prod(string(Int(e)) for e in
                (prev_closes_p, prev_lineskip, next_opens_p, next_lineskip))

    return case, space_before, space_after
end


"""
    paragraph_injector!(io, to_inject, m; to_html)

Add something to a buffer corresponding to an inline element; depending on the
neighbouring objects, different `<p>`, `</p>` or `\\par ` tags will be used to
ensure that the overall HTML/LaTeX remains valid and carries the initial
intent. Note the whitespace after `\\par` to avoid having something like
`\\parand`.
"""
function paragraph_injector!(
            io::IOBuffer,
            to_inject::String,
            m::RegexMatch;
            to_html::Bool=true
            )::Nothing

    case, space_before, space_after = check_case(m, to_html)

    # There are 2^4 = 16 cases corresponding to the 16 combinations of
    # - is the previous element a text block (T</p>) or not (B)
    # - is there a line skip before (LS)
    # - is the next element a text block (<p>T) or not (B) (LaTeX: always true)
    # - is there a line skip after (LS)
    #
    # NOTE: some cases are redundant or irrelevant (e.g. for LaTeX), but it's
    # easier to maintain to have all possible combinations here in one shot.
    # Basically `<p>` -> `` in LaTeX and `</p>` -> `\par`
    #

    h = ("", "")
    l = ("", "")
    if case == "0000"
        # (B _ B)
        # => html: (B <p> _ </p> B)
        h = ("<p>", "</p>")

    elseif case == "1000"
        # (T </p> _ B)
        # => html: (T _ </p> B)
        h = ("", "</p>")
    elseif case == "0100"
        # (B LS _ B)
        # => html: (B <p> _ </p> B)
        h = ("<p>", "</p>")
    elseif case == "0010"
        # (B _ <p> T)
        # => html: (B <p> _ T)
        # => latex: (B _ T)
        h = ("<p>", "")
        l = ("\n", "")
    elseif case == "0001"
        # (B _ LS B)
        # => html: B <p> _ </p> B
        h = ("<p>", "</p>")

    elseif case == "1100"
        # (T </p> LS _ B)
        # => html: (T </p> <p> _ </p> B)
        h = ("</p><p>", "</p>")
    elseif case == "0011"
        # (B _ LS <p> T)
        # => html: (B <p> _ </p> <p> T)
        # => latex: (B _ \par T)
        h = ("<p>", "</p><p>")
        l = ("\n", "\\par\n")
    elseif case == "0110"
        # (B LS _ <p>T)
        # => html: (B <p> _ T)
        # => latex: (B _ T)
        h = ("<p>", "")
        l = ("\n", "")
    elseif case == "1001"
        # (T </p> _ LS B)
        # => html: (T _ </p> B)
        h = ("", "</p>")
    elseif case == "1010"
        # (T </p> _ <p> T)
        # => html: (T _ T)
        # => latex: (T _ T)
        h = ("", "")
        l = ("", "")
    elseif case == "0101"
        # (B LS _ LS B)
        # => html: (B <p> _ </p> B)
        h = ("<p>", "</p>")

    elseif case == "1110"
        # (T </p> LS _ <p> T)
        # => html: (T </p> <p> _ T)
        # => latex: (T \par _ T)
        h = ("</p><p>", "")
        l = ("\\par\n", "")
    elseif case == "0111"
        # (B LS _ LS <p> T)
        # => html: (B <p> _ </p><p> T)
        # => latex: (B _ \par T)
        h = ("<p>", "</p><p>")
        l = ("\n", "\\par\n")
    elseif case == "1101"
        # (T </p> LS _ LS B)
        # => html: (T </p> <p> _ </p> B)
        h = ("</p><p>", "</p>")
    elseif case == "1011"
        # (T </p> _ LS <p>T)
        # => html: (T _ </p> <p> T)
        # => latex: (T _ \par T)
        h = ("", "</p><p>")
        l = ("", "\\par\n")

    elseif case == "1111"
        # (T </p> LS _ LS <p> T)
        # => html: (T </p> <p> _ </p> <p> T)
        # => latex: (T \par _ \par T)
        h = ("</p><p>", "</p><p>")
        l = ("\\par\n", "\\par\n")
    end
    pre  = ifelse(to_html, h[1], l[1])
    post = ifelse(to_html, h[2], l[2])
    write(io, pre, space_before, to_inject, space_after, post)
    return
end
