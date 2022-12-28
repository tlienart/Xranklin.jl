using PGFPlots

x = range(0, pi, length=500)
y = @. sin(exp(x)) * sinc(x)

Plots.Linear(x, y, style="smooth")