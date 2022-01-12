+++
showtoc = true
header = "Code blocks"
menu_title = header
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
\skip

## Syntax for executable code blocks

Beyond the syntax introduced briefly above, there are several other ways of indicating
that a fenced code block should be executed:

* \triplebt`julia:name` &mdash; the language and the name of the block are explicit,
* \triplebt`:name` &mdash; the language is implicit, the name of the block is explicit,
* \triplebt`:` &mdash; the language and the name are implicit.

For all these you can also swap the colon ('`:`') with an exclamation mark ('`!`') with
the same effect.

When the language is implicit, it is taken from the page variable `lang` (with default
 `"julia"`).
When the name is implicit, a name is automatically generated and the output is placed
directly below the code.

Here's an example with implicit language and explicit name:

\showmd{
  ```:abc
  println("hello")
  ```
}

\showmd{
  \show{abc}
}

And here's an example with implicit language and implicit name (the output is shown
  automatically below the code):

\showmd{
  ```!
  1//2^2
  ```
}

Unless you intend to show the code output somewhere else than below the code block
or use a custom method to show the code output, this last syntax (where everything is implicit)
is likely the one you will want to use most often.

### Hiding lines of code

In some cases an executable code cell might need some lines of code to work which you don't
want to show.
You can indicate that a line should be hidden by adding `#hide` to it (case and spaces don't matter).
If you want to hide an entire code cell (e.g. you're just interested in the output) you can put `#hideall` in the code.

\showmd{
  ```!
  using Random #hide
  randstring(5)
  ```
}

\showmd{
  ```!
  #hideall
  a = 5
  b = 7
  println(a+b)
  true
  ```
}

\skip

## Understanding how things work

Each page can be seen as one "notebook".
All executed code blocks on the page are executed in one sandbox module
attached to that page and share the same scope.
That sandbox module also loads the content of `utils.jl` as a `Utils` module
and so all objects defined there can be accessed in any code block via
`Utils.$name` (see also [the page on Utils](/syntax/utils/)).

When a code block is executed, the code string as well as the output strings are
cached.
This allows code blocks to not be systematically re-executed if they don't need to be.
The cached representation can be _stale_ in which case the code block will be re-evaluated
as soon as the page changes.
When adding or modifying a code block, every code block below that one are re-executed.

Since `Utils` is loaded into the sandbox module attached to a page, if `utils.jl` changes,
the entirety of the page "notebook" is marked as stale and will be re-run to guarantee
that it uses the latest definitions from Utils (even if it doesn't use Utils at all).
In that sense changing `utils.jl` amounts to clearing the entire cache and re-building
the website (see also [the page discussing Utils](/syntax/utils/)).

### What to do when things go wrong

While hopefully this shouldn't happen too often, two things can go wrong:

1. some code fails in an un-expected way (e.g.: it calls objects which it should have access to but doesn't seem to),
1. the output of an auto-cell is incorrect (either wasn't refreshed or some other random output that you didn't expect).

In both cases, if you can reproduce what led to the problem, kindly open an issue on Github.
Both problems will typically be addressed by clearing the cache which will force all code cells
to be re-evaluated in order.

To do this you can either call `serve(..., clear=true)` which will clear the entire cache
and rebuild everything from scratch or, if the problem is just on a single page, you can
temporarily set the [page variable](/syntax/vars+funs/) `ignore_cache` to `true` and re-start the server, this will ignore
the cache for that specific page and re-evaluate all code blocks.

## Output of executable code blocks


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
in your `Utils`: the string returned by the call to that function is then added,
1. the object can be shown as an SVG or PNG image: the image is automatically saved to
an appropriate location and shown (with priority to the SVG output),
1. otherwise: the output of `Base.show(result)` is added in a code block.

Note that you can also suppress the display of a code block result by adding a final `;` to the code.

\note{
  When capturing `stdout` during a code-cell evaluation, the logging level is
  such that `@info` and `@warn` won't show up.
  This is to prevent getting spurious information being shown on your website from
  packages precompiling upon CI deployment. \\
  Long story short: avoid using these macros in your code cells.
}

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

If the result is showable as SVG or PNG then a relevant file (`.svg` or `.png`) is
generated and the image is inserted with

```html
<img class="code-figure" src="...generated_path_to_img...">
```

For instance:

\showmd{
  ```!
  using Images
  rand(Gray, 2, 2)
  ```
}

If you inspect the HTML, you will see that the image displayed corresponds to a generated path that looks like `/assets/syntax/code/figs-html/__autofig_911582796084046168.svg`.
The generated path is built as `/assets/[source-path]/figs-html/[gen]` where `gen` is built out of the hash of the code that generated the image:

```!
hash("""
  using Images
  rand(Gray, 2, 2)
  """ |> strip
  ) |> string
```

\skip

### Custom show

If you have defined a custom `html_show(r)` in your `Utils` that accepts an object of the type of the result of a code cell and returning a string, then that will be used.

For instance in the `utils.jl` for the present website, we've defined

```julia
struct Foo
    x::Int
end
html_show(f::Foo) = "<strong>Foo: $(f.x)</strong>"
```

We can use the type `Foo` by indicating it is defined in `Utils` and the custom show method will be used:

\showmd{
  ```!
  Utils.Foo(1)
  ```
}

\note{
  You can refer to any object defined in `utils.jl` with the syntax `Utils.$name_of_object`.
}


### What if the code errors?

If there's an error in the code, no result will be shown and `stderr` will
capture a trimmed stacktrace of the problem which will be displayed:

\showmd{
  ```!
  sqrt(-1)
  ```
}

### In what path does the code run?

In the same path as where `serve` was called, but since you could call `serve()`
from within the site folder or `serve("path/to/folder")` this path can vary.
As a consequence, if you want a code cell to do something with a path (e.g. read or write a file),
use `Utils.path(:folder)` as the base path pointing to your website folder.
You can also use `Utils.path(:site)` as the base path pointing to the website build folder.

For instance let's say you want to save a DataFrame to a CSV that you can link to
as an asset on your site:

```!
using DataFrames, CSV
build_dir  = Utils.path(:site)
target_dir = mkpath(joinpath(build_dir, "assets", "data"))
df = DataFrame(A=1:4, B=["M", "F", "F", "M"])
CSV.write(joinpath(target_dir, "data1.csv"), df);
```

this outputs nothing but it does save `data1.csv` in the build folder at location
`/assets/data/` so that you could then link to it explicitly:

\showmd{
  click on [this link](/assets/data/data1.csv) to download the CSV corresponding
  to the dataframe above.
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

For instance let's say you want to use `CSV` and `DataFrames`, you would then,
in a Julia session, do:

```julia-repl
julia> using Pkg; Pkg.activate("path/to/website/folder")
julia> Pkg.add(["CSV", "DataFrames"])
```

It's important your website folder has its dedicated environment.
Especially if you use continuous integration (CI, e.g. GitHub Actions)
to build and deploy the website as that CI will need a correct `Project.toml`
to load the packages needed to properly build the website.

```!
using DataFrames
df = DataFrame(A=1:4, B=["M", "F", "F", "M"])
```

\skip

### Cache and packages

If you start a new Julia session and have a page where some code uses a package
(say `DataFrames`) and you add a new cell at the end of the page, only that
cell will be re-executed and, therefore, won't have access to `DataFrames` unless
you re-evaluate the whole page **or** you explicitly add `using DataFrames` in that
new cell.

Alternatively, you can

* set the current page to ignore the cache at start by setting the page variable `ignore_cache` to `true` and restart the server,
* clear the entire site cache

In the first case, on the initial full pass upon server launch, pages with `ignore_cache = true` will re-evaluate all their cells.
In the second case, on the initial full pass upon server launch, all pages will re-evaluate all their cells.

### Executing Python code

\todo{...}
