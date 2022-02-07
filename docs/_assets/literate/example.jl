# ### Rational numbers
#
# In julia rational numbers can be constructed with the `//` operator.
# Lets define two rational numbers, `x` and `y`:

## Define variable x and y
x = 1//3
y = 2//5

# When adding `x` and `y` together we obtain a new rational number:

z = x + y

# ### Plots
# Here's another "cell" with a plot:

using PyPlot
x = range(0, pi, length=250)
y = @. exp(-x * sin(x^2))
figure(figsize=(8, 6))
plot(x, y)
gcf()

# Or here one with a printout

for i in 1:5
    println("*"^i)
end
