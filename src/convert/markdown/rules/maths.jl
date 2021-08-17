# inline maths $ $
html_math_a(b::Block,  c::LocalContext) = "\\($(math(b, c))\\)"
latex_math_a(b::Block, c::LocalContext) = "\$$(math(b, c; tohtml=false))\$"

# display math $$ $$
html_math_b(b::Block,  c::LocalContext) = dmath(b, c)
latex_math_b(b::Block, c::LocalContext) =
    "\\begin{equation}$(math(b, c; tohtml=false))\\end{equation}"

# display math \[ \]
html_math_c  = html_math_b
latex_math_c = latex_math_b
