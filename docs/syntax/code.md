+++
showtoc = true
header = "Code cells"
+++

## Overview

Franklin supports executing Julia code blocks and using or showing their output.
Each page can be seen as one "notebook". All executed code blocks on the page are
executed in one sandbox module and share the same scope.

Code blocks are named, either explicitly or implicitly.
When naming code blocks explicitly, you can control where you place the output.
In the implicit case, the output is directly placed below the code.

Once run, a code block and its results are cached and won't be re-executed
unless it needs to be (e.g. if the code changed or if a code block before it
changes).

## Executing Julia code

The syntax for a named executed code block is

````markdown
```julia:name
...
```
````

where `name` is a name without spaces (e.g. `ex1` or `case_abc` or `foo-bar`).
This name can then be used further on with `\show{name}` to show the output.

\showmd{
  ```julia:example-1
  a = 1+2+3+4+5
  b = (5 + 1) * 5 // 2
  @show b
  println("$a, $b")
  a == b
  ```
}

You can then place the output corresponding to that block as

\showmd{
  \show{example-1}
}

### XXX

\showmd{
  ```!
  1
  ```
}

\showmd{
  ```!
  println("foo")
  ```
}

\showmd{
  ```!
  using Images
  rand(Gray, 2, 2)
  ```
}

<!-- \showmd{
  ```julia:ex
  using Images
  rand(Gray, 2, 2)
  ```
}

\showmd{
  \show{ex}
} -->

<!--

As we indicated above, all code cells on a page share the same scope so for instance this is fine:

\showmd{
  ```julia:defs-1
  a = 7
  b = a^2 - 1
  ```
  ```julia:show-1
  println(b)
  ```
  \show{show-1}
}

### Using packages

You can use packages in code cells.
The first thing to do is to add the package to the environment associated with the website.
One way to do this is to

* `cd` to the website folder
* `] activate .`
* `] add PackageName`

this will create (or extend) a `Project.toml` file at the root of your website folder.
It's important to set this so that when deployed remotely (e.g. on GitHub CI), the correct
environment is loaded with the packages you need.

Let's say you've added [DataFrames.jl](dataframes) to your environment, you can then use it
as you would in a standard Julia session:

\showmd{
  ```julia:ex-df
  using DataFrames
  df = DataFrame(A=1:3, B=5:7, fixed=1)
  ```
  @@code-output \show{ex-df} @@
}

### Plots

\showmd{
  ```julia:fig1
  using PyPlot
  x = range(-1, 1, length=100)
  y = @. x^2 * sin(x)
  f = figure(figsize=(8, 6))
  plot(x, y)
  f
  ```

  @@center \show{fig1} @@
}


### Hiding lines

## Auto-cells

### Suppressing output

`showall=false`

## Executing non-Julia code


```julia:exa
2+3+4
```

\show{exa}
 -->

<!-- ```!
5+7
```

```!
println("hello")
5^2
```


## (XXX) Utils and page variables -->
