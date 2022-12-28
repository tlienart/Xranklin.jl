using UnicodePlots

x = range(0, pi, length=500)
y = @. sin(exp(x)) * sinc(x)

lineplot(x, y,
    xlabel="x",
    ylabel="y",
    border=:dotted,
    xlim=[0,pi],
    ylim=[-0.2,1]
)