"""
    convert_md(md, c; tohtml, nop, kw...)

Take a markdown string `md` and convert it either to html or latex in a given
local context `c`.

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
function convert_md(
            md::SS,
            c::Context;
            # kwargs
            tohtml::Bool = true,
            nop::Bool    = false,
            error_backtracking_iteration::Int = 0,
            kw...
        )::String

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
    groups = nothing
    try
        __t = tic()
        parts  = FP.md_partition(md; kw...)
        toc(__t, "convertmd / partition")
        __t = tic()
        groups = parts |> FP.md_grouper
        toc(__t, "convertmd / grouping")
    catch e
        if isa(e, FP.FranklinParserException)
            # if it comes directly from the first pass processing a file
            lc_file = path(c.glob, :folder)/c.rpath
            if c isa LocalContext && !is_recursive(c) && isfile(lc_file)
                # overwrite md to make sure we're using the original stuff
                md  = read(lc_file, String)
                rge = findfirst(e.context, md)
                la  = count('\n', md[begin:rge[1]]) + 1
                lb  = la + count('\n', subs(md, rge))
                msg = e.msg * """

                    Check file '$(c.rpath)' around lines L$la-L$lb.
                    """
                setvar!(c, :_has_parser_error, true)
                @error msg

                # try some backtracking
                if error_backtracking_iteration < 3
                    sub_md = subs(md, firstindex(md), prevind(md, rge[1]))
                    error_backtracking_iteration += 1
                    attempt = convert_md(sub_md, c;
                        tohtml, nop, error_backtracking_iteration, kw...
                    )
                    trunc = "truncated content, a parsing error occurred at " *
                            "some point after this"
                    return attempt * (tohtml ?
                        "<span style=\"color:red\">... $trunc ...</span>" :
                        "\\\\\\\\\\textbf{... $trunc ...}"
                    )
                end

            # comes from processing a string, or recursive processing
            else
                @error e.msg
            end
            return ""
        end
        rethrow(e)
    end

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
    __t = tic()
    for g in groups
        if g.role in (:PARAGRAPH, :PARAGRAPH_NOP)
            __ti = tic()
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
            toc(__ti, "convertmd / paragraph")

        elseif g.role == :LIST
            __ti = tic()
            convert_list(io, g, c; tohtml, kw...)
            toc(__ti, "convertmd / list")

        elseif g.role == :TABLE
            __ti = tic()
            convert_table(io, g, c; tohtml, kw...)
            toc(__ti, "convertmd / table")

        # environment groups (begin...end)
        elseif startswith(string(g.role), "ENV_")
            __ti = tic()
            b = try_resolve_lxenv(g.blocks, c; tohtml)
            write(io, convert(b, c))
            toc(__ti, "convertmd / env")

        # all other groups are constituted of a single block
        else
            __ti = tic()
            write(io, convert(first(g.blocks), c))
            toc(__ti, "convertmd / $(first(g.blocks).name)")
        end
    end
    toc(__t, "convertmd / group conversion")
    return String(take!(io))
end

convert_md(s::String, a...; kw...) = convert_md(subs(s), a...; kw...)


function math(md::SS, lc::LocalContext; kw...)
    lc.is_recursive[] = lc.is_math[] = true
    r = convert_md(md, lc; kw...)
    lc.is_recursive[] = lc.is_math[] = false
    return r
end
math(md::String, c; kw...) = math(subs(md), c; kw...)
math(b::Block, c; kw...)   = math(content(b), c; kw...)


function html(md::SS, c::Context; kw...)
    r = convert_md(md, c; kw...)
    (is_recursive(c) | is_glob(c)) && return r
    return html2(r, c)
end
html(md::SS; rpath="__local__", kw...) = html(md, DefaultLocalContext(; rpath); kw...)
html(md::String, c...; kw...) = html(subs(md), c...; kw...)

function latex(md::SS, c::Context; kw...)
    r = convert_md(md, c; tohtml=false, kw...)
    (is_recursive(c) | is_glob(c)) && return r
    return latex2(r, c)
end
latex(md::SS; rpath="__local__", kw...) = latex(md, DefaultLocalContext(; rpath); kw...)
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
    dmath(b, lc)

Display math block on a page with HTML output and processing of possible
label command. If a labelcommand is found, the output is preceded with
an anchor.
"""
function dmath(b::Block, lc::LocalContext)
    hasmath!(lc)
    math_str = content(b)
    anchor   = ""
    cntr     = (eqrefs(lc)["__cntr__"] += 1)
    # check if there's a \label{...}, if there is, process it
    # then remove it & do the rest of the processing
    if (label_match = match(MATH_LABEL_PAT, math_str)) !== nothing
        id       = string_to_anchor(string(label_match.captures[1]))
        class    = getvar(lc, :anchor_class, "anchor") * " " *
                   getvar(lc, :anchor_math_class, "anchor-math")
        anchor   = html_a(; id, class)
        math_str = replace(math_str, MATH_LABEL_PAT => "") |> subs
        # keep track of the reference + numbering
        eqrefs(lc)[id] = cntr
    end
    # is_recursive(lc) && return "\\[ $(math(math_str, lc)) \\]\n"
    return "$anchor\\[ $(math(math_str, lc)) \\]\n"
end
