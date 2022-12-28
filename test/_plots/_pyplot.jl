using PyPlot

x = range(0, pi, length=500)
y = @. sin(exp(x)) * sinc(x)

figure(figsize=(6, 4))
plot(x, y)
gcf() # this is necessary