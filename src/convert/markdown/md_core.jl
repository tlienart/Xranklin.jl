# possible inline blocks
# * TEXT                    | rules/text    ✓
# * COMMENT                 | skipped       ✓
# * RAW_HTML                | rules/text    ✓
# * EMPH*                   | rules/text    ✓
# * LINEBREAK               | rules/text    ✓
# * CODE_INLINE
# * MATH_INLINE
# * AUTOLINK
# * LINK*
# * CU_BR, LX_COM
# * LX_NEW*
# * DBB
# * RAW_INLINE

# possible blocks (single)
# * BLOCKQUOTE
# * TABLE
# * LIST
# * MD_DEF_BLOCK, MD_DEF    | rules/text
# * CODE_BLOCK*
# * MATH_DISPL*
# * DIV                     | rules/text
# * H*
# * HRULE                   | rules/text
# * LX_ENV
# * RAW

"""
    convert_md(md, c; tohtml, nop, kw...)

Take a markdown string `md` and convert it either to html or latex in a given
context `c`.

## Kwargs

    * tohtml=true: whether to convert to html or to latex (if false).
    * nop=false:   whether to delimit paragraphs (e.g. with `<p>...</p>`) or
                    not. Specifically in resolving a lx command from
                    definition (i.e. not a lxfun) we assume the command will
                    not break the current paragraph. See `try_resolve_lxcom`.
    * kw...:       kwargs passed to `form_groups` and, through it, to the
                    `md_partition` function. An important one is `disable`
                    which allows the user to specify a number of tokens that
                    should be ignored in the partitioning.
"""
function convert_md(md::SS, c::Context;
                    tohtml::Bool=true, nop::Bool=false, kw...)
    # partition the markdown and form groups (paragraphs)
    groups = FP.md_partition(md; kw...) |> FP.md_grouper
    # stream to which the converted text will be written
    io     = IOBuffer()

    convert    = html
    before_par = "<p>"
    after_par  = "</p>\n"
    if !tohtml
        convert    = latex
        before_par = ""
        after_par  = "\\par\n"
    end

    # in some recursive contexts like the resolution of a lx command, we
    # don't want to set a paragraph
    nop && (before_par = after_par = "")

    # go over each group, if it's a paragraph add the paragraph separators
    # around it, then convert each block in the group and write that to stream
    for g in groups
        if g.role == :PARAGRAPH
            process_latex_objects!(g.blocks, c; tohtml)
            if !all(isempty, g.blocks)
                write(io, before_par)
                pio = IOBuffer()
                for b in g.blocks
                    write(pio, convert(b, c))
                end
                write(io, strip(String(take!(pio))))
                write(io, after_par)
            end

        # environment groups (begin...end)
        elseif startswith(string(g.role), "ENV_")
            b = try_resolve_lxenv(g.blocks, c; tohtml)
            write(io, convert(b, c))

        # all other groups are constituted of a single block
        else
            write(io, convert(first(g.blocks), c))
        end
    end
    return String(take!(io))
end
convert_md(md::String, c::Context; kw...) = convert_md(subs(md), c; kw...)

function html(md::SS, c::Context=DefaultLocalContext(); kw...)
    r = convert_md(md, c; kw...)
    return html2(r, c)
end
html(md::String, c...; kw...)  = html(subs(md), c...; kw...)

function latex(md::SS, c::Context=DefaultLocalContext(); kw...)
    r = convert_md(md, c; tohtml=false, kw...)
    return latex2(r, c)
end
latex(md::String, c...; kw...) = latex(subs(md), c...; kw...)
