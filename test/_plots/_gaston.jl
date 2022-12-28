using Gaston
set(term="qt")

x = range(0, pi, length=500)
y = @. sin(exp(x)) * sinc(x)

plot(x, y)