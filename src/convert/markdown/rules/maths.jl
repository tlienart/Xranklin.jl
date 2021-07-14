# inline maths $ $
html_math_a(b::Block, c::Context)  = "\\($(math(b, c))\\)"
latex_math_a(b::Block, c::Context) = "\$$(math(b, c))\$"

# display math $$ $$
html_math_b(b::Block, c::Context)  = "\\[$(math(b, c))\\]"
latex_math_b(b::Block, c::Context) = "\\begin{equation}$(math(b, c))\\end{equation}"

# display math \[ \]
html_math_c  = html_math_b
latex_math_c = html_math_b
