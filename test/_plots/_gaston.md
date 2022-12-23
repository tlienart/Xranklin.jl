```!
#hideall
tic_1 = parse(Int, get(ENV, "START", "0"))
tic_2 = time()
```

## Gaston

Dependencies (GA):

```!
println(get(ENV, "SETUP", ""))
```

Example

```!
using Gaston
set(term="qt")
x = range(0, pi, length=500)
y = @. sin(exp(x)) * sinc(x)
plot(x, y)
```

### Timers

```!
# hideall
using Dates
toc = datetime2unix(now())
δ1  = round( toc - tic_2, digits=2)         # cell exec in seconds
δ2  = round((toc - tic_1) / 60, digits=2)   # build exec in mins
println("Code execution time: $(δ1) seconds.")
println("Total time taken (setup + build): $(δ2) minutes.")
```
