using CairoMakie
CairoMakie.activate!()

x = range(0, pi, length=500)
y = @. sin(exp(x)) * sinc(x)

lines(x, y)