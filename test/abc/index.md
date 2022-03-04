+++
header = "foo"
+++

## Hello

<!-- ```!
using UnicodePlots
plt = lineplot([-1, 2, 3, 7], [-1, 2, 9, 4],
               title="Example Plot", name="my line", xlabel="x", ylabel="y", border=:dotted)
``` -->

```!
# name: aaa
x = 4
foo bar #mock
```

```!
# name: bbb
println(x+1)
```

```!
# name: bbb2
println(2x)
```

---
Indep cell:
```!
# indep
# name: ccc
y = rand()+1
println(y^3)
```
---

```!
# name: ddd
println(rand())
println(x^2)
```
