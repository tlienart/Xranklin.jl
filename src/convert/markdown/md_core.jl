# possible inline blocks
# * TEXT                    | rules/text    ✓
# * COMMENT                 | skipped       ✓
# * RAW_HTML                | rules/text    ✓
# * EMPH*                   | rules/text    ✓
# * LINEBREAK               | rules/text    ✓
# * CODE_INLINE             | rules/code    ✓
# * MATH_INLINE             | rules/math    ✓
# * AUTOLINK                | XXX
# * LINK*                   | rules/link    ✓
# * CU_BR, LX_COM           | latex_objects
# * LX_NEW*                 | latex_objects
# * DBB                     | hfuns/*
# * RAW_INLINE              | rules/text

# possible blocks (single)
# * BLOCKQUOTE              |
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
                    should be ignored in the partitioning. Another one is
                    `tokens` which allows to pass tokens from a previous pass.
"""
function convert_md(md::SS, c::Context;
                    tohtml=true, nop=false, kw...)
    # stream to which the converted text will be written
    io = IOBuffer()
    if is_math(c)
        blocks = FP.math_partition(md; kw...)
        process_latex_objects!(blocks, c; tohtml)
        for b in blocks
            write(io, b.ss)
        end
        return String(take!(io))
    end

    # partition the markdown and form groups (paragraphs)
    groups = FP.md_partition(md; kw...) |> FP.md_grouper

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
        if g.role in (:PARAGRAPH, :PARAGRAPH_NOP)
            par = g.role == :PARAGRAPH
            process_latex_objects!(g.blocks, c; tohtml)
            pio = IOBuffer()
            for b in g.blocks
                cb = convert(b, c)
                write(pio, cb)
            end
            bulk = strip(String(take!(pio)), '\n')
            if par
                write(io, before_par, bulk, after_par)
            else
                write(io, bulk)
            end

        elseif g.role == :LIST
            convert_list(io, g, c; tohtml, kw...)

        elseif g.role == :TABLE
            convert_table(io, g, c; tohtml, kw...)

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


function math(md::SS, c::LocalContext; kw...)
    c.is_recursive[] = c.is_math[] = true
    r = convert_md(md, c; kw...)
    c.is_recursive[] = c.is_math[] = false
    return r
end
math(md::String, c; kw...) = math(subs(md), c; kw...)
math(b::Block, c; kw...)   = math(content(b), c; kw...)


function html(md::SS, c::Context=DefaultLocalContext(); kw...)
    r = convert_md(md, c; kw...)
    is_recursive(c) && return r
    return html2(r, c)
end
html(md::String, c...; kw...)  = html(subs(md), c...; kw...)


function latex(md::SS, c::Context=DefaultLocalContext(); kw...)
    r = convert_md(md, c; tohtml=false, kw...)
    is_recursive(c) && return r
    return latex2(r, c)
end
latex(md::String, c...; kw...) = latex(subs(md), c...; kw...)


"""
    convert(block, ctx; tohtml)

Take a block and process it to return the corresponding html/latex in the
given context by applying the rule relevant to that block.
"""
function convert_block(b::Block, c::Context; tohtml=true)::String
    # early skips
    if b.name == :RAW
        return string(content(b))
    elseif b.name == :COMMENT
        return ""
    elseif b.name in (:RAW_BLOCK, :RAW_INLINE)
        return string(b.ss)
    end
    # other blocks
    n = lowercase(String(b.name))
    f = Symbol(ifelse(tohtml, "html", "latex") * "_$n")
    return eval(:($f($b, $c)))
end
html(b::Block, c::Context)  = convert_block(b, c)
latex(b::Block, c::Context) = convert_block(b, c; tohtml=false)


"""
    recurse(s, c; kw...)

Process a string in a recursive context.
"""
function recurse(s::SS, c::Context; tohtml=true, kw...)::String
    converter = ifelse(tohtml, html, latex)
    was_recursive = c.is_recursive[]
    c.is_recursive[] = true
    r = converter(s, c; kw...)
    c.is_recursive[] = was_recursive
    return r
end
rhtml(s::SS, c::Context; kw...)  = recurse(s, c; tohtml=true, kw...)
rlatex(s::SS, c::Context; kw...) = recurse(s, c; tohtml=false, kw...)

rhtml(s::String, c; kw...) = rhtml(subs(s), c; kw...)
rhtml(b::Block, c; kw...)  = rhtml(content(b), c; tokens=b.inner_tokens, kw...)

rlatex(s::String, c; kw...) = rlatex(subs(s), c; kw...)
rlatex(b::Block, c; kw...)  = rlatex(content(b), c; tokens=b.inner_tokens, kw...)


"""
    dmath(b, ctx)

Display math block on a page with HTML output and processing of possible
label command. If a labelcommand is found, the output is preceded with
an anchor.
"""
function dmath(b::Block, ctx::LocalContext)
    hasmath!(ctx)
    math_str = content(b)
    anchor   = ""
    cntr     = (eqrefs(ctx)["__cntr__"] += 1)
    # check if there's a \label{...}, if there is, process it
    # then remove it & do the rest of the processing
    if (label_match = match(MATH_LABEL_PAT, math_str)) !== nothing
        id       = string_to_anchor(string(label_match.captures[1]))
        class    = getvar(ctx, :anchor_class, "anchor") * " " *
                   getvar(ctx, :anchor_math_class, "anchor-math")
        anchor   = html_a(; id, class)
        math_str = replace(math_str, MATH_LABEL_PAT => "") |> subs
        # keep track of the reference + numbering
        eqrefs(ctx)[id] = cntr
    end
    is_recursive(ctx) && return "\\[ $(math(math_str, ctx)) \\]\n"
    return "$anchor\\[ $(math(math_str, ctx)) \\]\n"
end
