function html(b::Block, c::Context)
    n = lowercase(String(b.name))
    f = Symbol("html_$n")
    return eval(:($f($b, $c)))
end

function latex(b::Block, c::Context)
    n = lowercase(String(b.name))
    f = Symbol("latex_$n")
    return eval(:($f($b, $c)))
end

# --------------------------------------------------------------------------------------
#
# TEXT
#
function html_text(b::Block, ::Context)
    # extract the content and inject HTML entities etc (see FranklinParser.prepare_text)
    s = FP.prepare_text(b)
    return md2html(s)
end

function latex_text(b::Block, ::Context)
    s = FP.prepare_text(b)
    return md2latex(s)
end

#
# COMMENT
#
html_comment(b::Block,  ::Context) = ""
latex_comment(b::Block, ::Context) = ""

#
# Linebreak and Horizontal Rule
#
html_linebreak(b::Block, ::Context)  = "<br>"
latex_linebreak(b::Block, ::Context) = raw"\\"

html_hrule(b::Block,  ::Context) = "<hr>"
latex_hrule(b::Block, ::Context) = raw"\par\noindent\rule{\textwidth}{0.1pt}"

#
# RAW HTML
#
html_raw_html(b::Block,  ::Context)  = content(b)
latex_raw_html(b::Block, ::Context) = ""

#
# Code
#
html_code_inline(b::Block, ::Context) = "<code>$(content(b))</code>"

#
# DIV BLOCK
#
function html_div(b::Block, ctx::Context)
    classes = FP.get_classes(b)
    inner   = html(FP.default_md_partition(b), ctx)
    return """<div class="$classes">$inner</div>"""
end

function latex_div(b::Block, ctx::Context)
    return latex(FP.default_md_partition(b), ctx)
end
