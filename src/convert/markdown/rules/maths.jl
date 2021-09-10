# inline maths $ $
html_math_inline(b::Block,  c::LocalContext) = "\\($(math(b, c))\\)"
latex_math_inline(b::Block, c::LocalContext) = "\$$(math(b, c; tohtml=false))\$"

# display math $$ $$
html_math_displ_a(b::Block,  c::LocalContext) = dmath(b, c)
latex_math_displ_a(b::Block, c::LocalContext) =
    "\\begin{equation}$(math(b, c; tohtml=false))\\end{equation}"

# display math \[ \]
html_math_displ_b  = html_math_displ_a
latex_math_displ_b = latex_math_displ_a
