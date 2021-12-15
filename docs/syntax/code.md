+++
showtoc = true
header = "Code cells"
+++

\newcommand{\triplebt}{~~~<code>&#96;&#96;&#96;</code>~~~}

~~~
<style>
img.code-figure {
  max-width: 50%;
}
</style>
~~~

## Overview

Franklin supports executing Julia code blocks and using or showing their output.
Here is a basic example:

\showmd{
  ```julia:example
  # a very simple code 'cell'
  a = 1
  ```
}

At a high level, this both shows the code on the webpage (as illustrated above)
and also uses the running Julia session to execute the code so that the output
can be shown somewhere else:

\showmd{
  \show{example}
}

the syntax

````markdown
```julia:name
...
```
````

identifies a fenced code block as "executable" and assigns a name `name` which
allows to refer specifically to the output of that code block.

The command `\show{name}` then displays `stdout`, `stderr` and the result of
the code block if it's not `nothing`.

\note{
  At the moment, only Julia code can be executed.
  In the future, Python and R may also be directly supported via [PyCall] and [RCall].
  As [shown below](#executing_python_code), you can already do this manually within a Julia code block.
}

## Syntax for executable code block

Beyond the syntax introduced briefly above, there are several other ways of indicating
that a fenced code block should be executed:

* \triplebt`julia:name` &mdash; the language and the name of the block are explicit,
* \triplebt`:name` &mdash; the language is implicit, the name of the block is explicit,
* \triplebt`:` &mdash; the language and the name are implicit.

For all these you can also swap the colon (`:`) with an exclamation mark (`!`) with
the same effect.

When the language is implicit, it is taken from the page variable `:lang` (with default
 `"julia"` of course).
When the name is implicit, a name is automatically generated and the output is placed
directly below the code.

Here's a couple of examples:

\showmd{
  ```:abc
  println("hello")
  ```
}

\showmd{
  \show{abc}
}

\showmd{
  ```!
  1//2
  ```
}

Unless you intend to show the code output somewhere else than below the code block
or use a custom method to show the code output, this last syntax is likely the one
you'll want to use most often.

### Hiding lines of code (XXX)


## Output of executable code block


When evaluating a cell, Franklin captures `stdout`, `stderr` and, if the code
doesn't fail, the `result`.
When using the command `\show`, the output is placed in the following HTML:

```html
<div class="code-output">

  <!-- If stdout is not empty -->
  <pre><code clas="code-stdout language-plaintext">
    ...captured stdout...
  </code></pre>

  <!-- if stderr is not empty -->
  <pre><code class="code-stderr language-plaintext">
    ...captured stderr...
  </code></pre>

  <!-- if result is not nothing -->
   ...appropriate representation of the result...
</div>
```

This can be changed if you overwrite the `\show` command by defining a custom
`lx_show` function in your utils (see [how to define latex commands](/syntax/utils/)).

If the code block didn't fail, the _appropriate representation_ of a result that is
not `nothing` is obtained by considering the following cases in order:

1. there is a custom `html_show` function for `typeof(result)` that is defined
in your Utils: the string returned by the call to that function is then added,
1. the object can be shown as an SVG or PNG image: the image is automatically saved to
an appropriate location and shown (with priority to the SVG output),
1. otherwise: the output of `Base.show(result)` is added in a code block.

Note that you can suppress a code block's result by adding a final `;` to the code.

### Nothing to show

Nothing will be shown beyond `stdout` if

* the last command in the code block is a `@show` or returns `nothing`
* the last command in the code block is followed by `;`

For instance

\showmd{
  ```!
  a = 1//2
  @show a   # ==> last command is a show
  ```
}

\showmd{
  ```!
  println("hello")
  1;       # ==>  ';' suppresses the output
  ```
}

### Default show

For result that is not showable as an image or doesn't have a custom show, `Base.show`
will be applied with a result similar to what you would get in the Julia REPL

\showmd{
  ```!
  true
  ```
}

\showmd{
  ```!
  [1, 2, 3]
  ```
}

### Showable as SVG or PNG

If the result is showable as SVG or PNG then the relevant file (`.svg` or `.png`) is
generated and the image is inserted with

```html
<img class="code-figure" src="...generated_path_to_img...">
```

\showmd{
  ```!
  using Images
  rand(Gray, 2, 2)
  ```
}

### Custom show

If you've defined a custom `html_show(r)` accepting an object of the type of `result`
and returning a string, then that will be used.

For instance in the `utils.jl` for the present website, we've defined

```julia
struct Foo
    x::Int
end
html_show(f::Foo) = "<strong>Foo: $(f.x)</strong>"
```

\showmd{
  ```!
  Utils.Foo(1)
  ```
}

\note{
  Observe that you can refer to objects and functions defined in `utils.jl`
  with the syntax `Utils.$name`.
}


### What if the code errors?

If there's an error in the code, no result will be shown and `stderr` will
capture a trimmed stacktrace of the problem which will be displayed:

\showmd{
  ```!
  sqrt(-1)
  ```
}

### In what path does the code run

In the same path as where `serve` was called but since you could call `serve()`
from within the site folder or `serve("path/to/folder")` from outside of it,
this path may change.

If you want a code cell to do something with a path (e.g. read or write a file),
use `Utils.path(:folder)` as the base path pointing to your website folder.
You can also use `Utils.path(:site)` as the path pointing to the website build folder.

For instance you might want to save a figure in a specific location and load it
explicitly rather than use the automatic mode:

```!
build_dir  = Utils.path(:site)
target_dir = mkpath(joinpath(build_dir, "assets", "figs"))
using PyPlot
x = range(0, 3, length=100)
y = @. exp(x) * sin(x)
figure(figsize=(8, 6))
plot(x, y, lw=5)
axis("off")
savefig(joinpath(target_dir, "toy_fig.svg"));
```

this outputs nothing but it does save `toy_fig.svg` in the build folder at location
`/assets/figs/` so that you can then insert it explicitly:

\showmd{
  ![toy plot](/assets/figs/toy_fig.svg)
}

Another example is that you might want to write a file in the build dir:

```!
build_dir = Utils.path(:site)
open(joinpath(build_dir, "405.html"), "w") do f
  write(f, """
    Dummy page 405, <a href="/">return home</a>
    """
  )
end;
```

The above code block writes a dummy HTLM page `405.html` in the build folder.
You can actually see it [here](/405.html).

\note{
  Do not use absolute paths since those might not exist in a continuous integration
  environment. Do use `Utils.path(:folder)` or `Utils.path(:site)`
  as your base path and use `joinpath` to point to your target.
}

## Using packages

You can use packages in executable code blocks but you should add those to the
environment corresponding to the website folder while the server is not running.

For instance let's say you want to use `PyPlot` and `DataFrames`, you would then,
in a Julia session, do:

```julia-repl
julia> using Pkg; Pkg.activate("path/to/website/folder")
julia> Pkg.add(["PyPlot", "DataFrames"])
```

It's important your website folder has its dedicated environment.
Especially if you use continuous integration (CI, e.g. GitHub Actions)
to build and deploy the website as that CI will need a correct `Project.toml`
to load the packages needed to properly build the website.

```!
using DataFrames
df = DataFrame(A=1:4, B=["M", "F", "F", "M"])
```


```!
using PyPlot
x = range(-1, 1, length=100)
y = @. exp(-5x) * sinc(x)
figure(figsize=(8, 6))
plot(x, y, lw=7)
axis("off")
gcf()     # ⚠ it's the figure that's showable, not the plot
```

In the above example, note how the last command is `gcf()` as we need to retrieve
the showable object which is the figure, not the plot.


<!-- ### Executing Python code

Since you can use packages, you can use `PyCall` and `RCall`:

```!
using PyCall
math = pyimport("math")
math.sin(math.pi / 4)
``` -->

## Understanding how things work

Each page can be seen as one "notebook".
All executed code blocks on the page are executed in one sandbox module
attached to that page and share the same scope.
That sandbox module also loads the content of `utils.jl` as a `Utils` module
and so all objects defined there can be accessed in any code block via
`Utils.$name`.

When a code block is executed, the code string as well as the output strings are
cached.
This allows code blocks to not be systematically re-executed if they don't need to be.

The cached representation can be _stale_ in which case the code block will be re-evaluated
as soon as the page changes.
When adding or modifying a code block, every code block below that one are re-executed.

Since Utils is loaded into the sandbox module attached to a page, if `utils.jl` changes,
the entirety of the page "notebook" is marked as stale and will be re-run to guarantee
that it uses the latest definitions from Utils (even if it doesn't use Utils at all).
In that sense changing `utils.jl` amounts to clearing the entire cache and re-building
the website (see also [the page on utils](/syntax/utils/)).

### What to do when things go wrong

While hopefully this shouldn't happen too often, two things can go wrong:

1. some code fails in an un-expected way (e.g.: it calls objects which it should have access to but doesn't seem to),
1. the output of an auto-cell is incorrect (either wasn't refreshed or some other random output that you didn't expect).

In both cases, if you can reproduce what led to the problem, kindly open an issue on Github.
Both problems will typically be addressed by clearing the cache which will force all code cells
to be re-evaluated in order.
