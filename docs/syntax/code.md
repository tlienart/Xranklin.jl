+++
showtoc = true
header = "Code cells"
+++

\newcommand{\triplebt}{~~~<code>&#96;&#96;&#96;</code>~~~}

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

The full syntax for a named executed code block is

````markdown
```julia:name
...
```
````

where `name` is a name without spaces (e.g. `ex1` or `case_abc` or `foo-bar`).
This name can then be used further on with `\show{name}` to show the output.

\showmd{
  ```julia:example
  # a very simple assignment
  a = 1
  ```
}

At this point note that only the code is shown, highlighted, it has been executed
but the output is not shown yet. To show it, you can use `\show{name}`:

\showmd{
  \show{example}
}

\note{
  At the moment, only Julia code can be executed.
  In the future, Python and R may also be directly supported via [PyCall] and [RCall].
  As [shown below](#executing_python_code), you can already do this manually within a Julia code block.
}

### Alternative syntaxes

Often, your entire website will only use one language (e.g. Julia) and you may
also often want the output to be shown directly below the code.
To accommodate for these cases, the following syntaxes are allowed:

* \triplebt`:name` &mdash; the language is implicit and taken from the page variable `:lang`
(default: `"julia"`),
* \triplebt`:` &mdash; the language and the name are implicit, the output is placed directly
below the code.

In the above, the colon (`:`) can be replaced with a `!` with the same meaning.
For instance:

\showmd{
  ```!
  println("hello")
  ```
}

### Customising the output

When evaluating a cell, Franklin captures `stdout`, `stderr` and the `result`.
When using the command `\show`, the output is placed in the following HTML:

```html
<div class="code-output">
  <!-- If stdout is not empty -->
   <pre><code clas="code-stdout language-plaintext"> ...stdout... </code></pre>
  <!-- if stderr is not empty -->
   <pre><code class="code-stderr language-plaintext"> ...stderr... </code></pre>
  <!-- (1) if result is nothing: stop here -->
  <!-- (2) if there's a custom show -->
   ...custom show...
  <!-- (3) if result is showable as an image (svg, png, ...) -->
   <img class="code-figure" src="...generated-path...">
  <!-- (4) otherwise fallback on default Base.show -->
   <pre><code class="code-result language-plaintext"> ...default show... </code></pre>
</div>
```

You can of course overwrite the `\show` command
(cf. [how to define latex commands](/syntax/utils/)) with whatever behaviour
you would prefer.

To display the result of the code cell, the following 4 cases are considered:

1. the result is `nothing` in which case nothing (empty string) is added,
1. there is a custom `html_show` function for `typeof(result)` that you defined in your Utils:
the string returned by the call to that function is then added,
1. the object can be shown as an SVG or PNG img=age: the image is automatically saved to
an appropriate location and shown (priority to the SVG output),
1. otherwise: the output of `Base.show(result)` is added in a code block.

Let's have a few examples for this.

**Default show**: stdout is shown if not empty and the result is shown as per `Base.show(result)`.

\showmd{
  ```!
  println("hello")  # ==> stdout
  a = [1,2,3]       # ==> default show
  ```
}

**Default show with suppressed result**: if the code ends with a `;` or the last command is a `@show`, the
result is considered to be `nothing`.

\showmd{
  ```!
  a = 1;  # ==> nothing to show
  ```
}

\showmd{
  ```!
  a = "hello"
  @show a  # ==> stdout + nothing to show
  ```
}

**Error in code**: stderr is shown, there's no result.


\showmd{
  ```!
  sqrt(-1) # ==> stderr, no result
  ```
}

**Result can be shown as an image**:

\showmd{
  ```!
  using Images
  rand(Gray, 2, 2) # ==> shown as SVG
  ```
}

**Custom show**:

\showmd{
  ```!
  Utils.Foo(1)
  ```
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

### YYY

```:abc
1+1
```

\show{abc}

```!
println("hello")
```


\showmd{
  ```!
  a=3
  ```
}

\showmd{
  ```:exa
  a = 5
  b = 7
  a * b
  ```
  and
  \show{exa}
}

### Executing Python code

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
