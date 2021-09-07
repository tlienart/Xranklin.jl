form_groups(md::SS; kw...)     = FP.md_partition(md; kw...) |> FP.md_grouper
form_groups(md::String; kw...) = form_groups(subs(md))

prepare_md(md; kw...) = form_groups(md; kw...)

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


function convert_md(md, c::Context; tohtml::Bool=true, nop::Bool=false, kw...)
    groups = prepare_md(md; kw...)
    io = IOBuffer()

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
    if nop
        before_par = after_par = ""
    end

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

        elseif startswith(string(g.role), "ENV_")
            b = try_resolve_lxenv(g.blocks, c; tohtml)
            write(io, convert(b, c))

        else
            write(io, convert(first(g.blocks), c))
        end
    end

    return String(take!(io))
end

html(md, c::Context=DefaultLocalContext(); kw...) =
    (r = convert_md(md, c; kw...); html2(r, c))
latex(md, c::Context=DefaultLocalContext(); kw...) =
    (r = convert_md(md, c; tohtml=false, kw...); latex2(r, c))

# """
#     md2x(s::String, tohtml::Bool)
#
# Wrapper around what CommonMark does to keep track of spaces etc which CM
# strips away but which are actually needed in order to adequately resolve
# inline inserts. Leads to either html or latex based on the case.
# """
# function md2x(s::String, tohtml::Bool)::String
#     isempty(s) && return ""
#     if tohtml
#         r = CM.html(cm_parser(s))
#     else
#         r = CM.latex(cm_parser(s))
#     end
#     # if there was only r"\s*" in s, preserve that unless it's a lineskip
#     if isempty(r)
#         return ifelse(occursin("\n\n", s), LINESKIP_PH, s)
#     end
#     # check if the block is preceded or followed by a lineskip (\n\n)
#     # or, by a space that we might have to preserve (e.g. inline)
#     # if that's the case, either inject an indicator or a space
#     pre  = ""
#     post = ""
#     if startswith(s, LINESKIP_PAT)
#         pre = LINESKIP_PH
#     elseif startswith(s, WHITESPACE_PAT)
#         pre = " "
#     end
#     if endswith(s, LINESKIP_PAT)
#         post = LINESKIP_PH
#     elseif endswith(s, WHITESPACE_PAT)
#         post = " "
#     end
#     return pre * r * post
# end
#
# md2html(s::String)  = md2x(s, true)
# md2latex(s::String) = md2x(s, false)

#
# """
#     md_core(parts, ctx; tohtml)
#
# Function processing blocks in sequence and assembling them while resolving
# possible balancing issues.
# """
# function md_core(
#             parts::Vector{Block},
#             c::Context;
#             tohtml::Bool=true
#             )::String
#
#     transformer = ifelse(tohtml, html, latex)
#     process_latex_objects!(parts, c; tohtml)
#
#     io = IOBuffer()
#     inline_idx = Int[]
#     for (i, part) in enumerate(parts)
#         if part.name in INLINE_BLOCKS
#             write(io, INLINE_PH)
#             push!(inline_idx, i)
#         else
#             write(io, transformer(part, c))
#         end
#     end
#     interm = String(take!(io))
#     return resolve_inline(interm, parts[inline_idx], c, tohtml)
# end
