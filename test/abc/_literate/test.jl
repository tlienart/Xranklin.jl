# # Rational numbers
#
# In julia rational numbers can be constructed with the `//` operator.
# Lets define two rational numbers, `x` and `y`:

## Define variable x and y
x = 1//3
y = 2//5

# When adding `x` and `y` together we obtain a new rational number:

z = x + y * 2

# A

println("foo")
z * 2

# B

println("hello")

# C

using PyPlot
figure(figsize=(8, 6))
plot([1,2,3],[1,2,3])
gcf()


# D

z = 2

# E

x = range(0, 5, length=100)
y = @. exp(-x * sin(x^2))
figure(figsize=(8, 6))
plot(x, y)
gcf()
