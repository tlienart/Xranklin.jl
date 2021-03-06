# inline maths $ $
html_math_a(b::Block, c::Context) = "\\($(math(b, c))\\)"
latex_math_a(b::Block, c::Context) = "\$$(math(b, c))\$"

# display math $$ $$
html_math_b(b::Block, c::Context) = ""
latex_math_b(b::Block, c::Context) = ""

# display math \[ \]
html_math_c(b::Block, c::Context) = ""
latex_math_c(b::Block, c::Context) = ""
