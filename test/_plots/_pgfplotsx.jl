using PGFPlotsX

x = range(0, pi, length=500)
y = @. sin(exp(x)) * sinc(x)

@pgf PGFPlotsX.Axis(
    Plot(
        {no_marks},
        Table(x, y)
    )
)