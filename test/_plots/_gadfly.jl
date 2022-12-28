using Gadfly

x = range(0, pi, length=500)
y = @. sin(exp(x)) * sinc(x)

plot(x=x, y=y, Geom.path)