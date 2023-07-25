<!--
LAST REVISION: Jan 14, 2022 (full page ok)
 -->


+++
showtoc = true
header = "Code blocks (part 1)"
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
can be shown somewhere else via the `\show` command:

\showmd{
  \show{example}
}

The orange box helps indicate what corresponds to the output of an executed code cell.
This is just the styling we use on the present site though, you can of course control this
yourself by styling the class `.code-output` or one of the more specific sub-classes
(see [the section on code output](#output_of_executable_code_blocks)).

The syntax

````markdown
```julia:name
...
```
````

identifies a fenced code block as "executable" and assigns a name '`name`' which
allows to refer specifically to the output of that code block.

The command `\show{name}` then displays `stdout`, `stderr` and the result of
the code block if it's not `nothing`.

\note{
  At the moment, only Julia code can be executed, though of course you can use
  [PyCall] or [RCall] to execute Python or R code.
  This is [illustrated in the examples](#executing_python_code).
}
\lskip

## Syntax for executable code blocks

Beyond the syntax introduced briefly above, there are several other ways of indicating
that a fenced code block should be executed:

* \triplebt`julia:name` &mdash; the language and the name of the block are explicit,
* \triplebt`:name` &mdash; the language is implicit, the name of the block is explicit,
* \triplebt`:` &mdash; the language and the name are implicit.

For all these you can swap the colon (`:`) for an exclamation mark (`!`) with the same
effect (see examples below).

\note{
  When specifying the language, you can add a whitespace before the execution symbol
  to help editors such as VSCode to highlight the code block properly.
  For instance:
  ````
  ```julia !ex
  ...
  ```
  ````
}


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

Unless you intend to show the code output somewhere else than below the code block,
or use a custom method to show the code output, this last syntax (where everything is implicit)
is likely the one you will want to use most often.

\tip{
  When debugging, you might like to double the execution marker (`!!` or `::`) which will force
  the cell to be re-evaluated; this can be useful for debugging but should be removed as soon as
  you fixed the problem as it otherwise incurs unnecessary cost when building the site.
  See also [what to do when things go wrong](#what_to_do_when_things_go_wrong) below.
}

### Hiding lines of code

In some cases an executable code cell might need some lines of code to work which you don't
want to show.
You can indicate that a line should be hidden by adding `#hide` to it (letter case and whitespace
  don't matter).
If you want to hide an entire code cell (e.g. you're just interested in the output)
you can put `#hideall` in the code.

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

\lskip


### Mock lines

In some cases you might want to show a line of code without it being run.
The example below should make this clearer:

```
data = fetch("./tests/data.txt") # <-- depends on your setup
data = fetch("/user/$name/api")  # <-- what the user should do

plot(data)
```

In this example, you'd want to _run but hide_ the first line and _not run but show_ the second
line.
You already know `#hide`, the other one is `#mock` (also allowed: `#fake`, `#noexec`, `#norun`).

\showmd{
  ```!
  println("hello")   # hide  <-- executed, not shown
  println("not run") # mock  <-- shown, not executed
  ```
}


### Providing name hints

For auto-named code blocks (which you likely will want to use most of the time), you can provide
a name hint which will help identify what is being evaluated in the REPL output when you
build your site.

So for instance if you just write

\showmd{
  ```!
  println("hello")
  ```
}

when the page gets built, something like

```
evaluating cell auto_cell_5...
```

will be shown in the REPL.
But it can sometimes be useful to know precisely which block is being run and you can do
this by adding a "`# name: name hint`" line in your code:

\showmd{
  ```!
  # name: printing example
  println("hello!")
  ```
}

then, when the page gets built, something like

```
evaluating cell auto_cell_5 (printing example)...
```

will be shown in the REPL.


### Marking a cell as independent

If a code block is fully independent of any other code blocks on the page, **and** of the `Utils` module, you can mark it as _independent_ (with `# indep`), this will allow Franklin to skip re-evaluating this block when other code blocks around it change.

To clarify this, imagine you have a page with two blocks _A_ and _B_.
By default if _A_ is modified, _B_ will be re-evaluated because Franklin considers that _B_ might
depend on some things that _A_ defines.\\
However, if you know that _B_ is fully independent code, you can mark it as such and then when _A_ changes, _B_ will **not** get re-evaluated.

When marking a block as independent, the user guarantees to Franklin that:
1. the code does not depend on any other code block on the page,
1. no other code block on the page depends on that code block.

The marker for independence should be placed at the top of your code:

\showmd{
  ```!
  # indep
  x = 5
  println(x^2)
  ```
}

\tip{
  If all your code blocks are fast-running, you can ignore the `indep` trick.
  However if a block takes time to run, and you know that it is independent
  in the sense mentioned above, marking it explicitly will help make page reloads faster.
}

## REPL mode

Instead of `!` or `:` above, you can also use one of `>`, `;`, `]` and `?` to
mimick the corresponding REPL mode.
In the case of the `?` one, only a single line of input is allowed (other lines,
if provided, will be ignored).

#### REPL common mode

With the `>`, you indicate that the code cell should be split in the same way
as it would in the REPL:

\showmd{
  ```>
  a = 5
  b = 2;
  c = a + 3b
  println(c^2)
  ```
}

#### REPL shell mode

With the `;`, you indicate that the code cell should be executed as in the 
REPL shell mode:

\showmd{
  ```;
  echo abc
  date
  ```
}

#### REPL pkg mode

With the `]`, you indicate that the code cell should be executed as in the
REPL pkg mode, note that this will affect the environment the subsequent cells
are run in (only on that page, it won't affect the other pages which will
keep being run in the website environment unless otherwise specified):

```!
#hideall
using Pkg
pkg_path = Pkg.project().path;
```

\showmd{
  ```]
  activate --temp
  add StableRNGs
  st
  ```
  then
  ```!
  using StableRNGs
  rand(StableRNG(1))
  ```
}

```!
#hideall
Pkg.activate(pkg_path, io=IOBuffer());
```

#### REPL help mode

With the `?`, you indicate that the code cell should be executed as in the
REPL help mode. Note that only the first line of the cell will be considered
as the output will be displayed in a separate `div` with class `repl-help`
(which you should style).

The basic styling used here is:

\showmd{
  ~~~
  <style>
  .repl-help {
    margin-top: 1em;
    margin-left: 1em;
    padding: 1em;
    background-color: #fefee8;
    border: 1px solid yellow;
    border-radius: 10px;
    font-style: italic;
  }
  .repl-help h1 {
    font-size: 1.1em;
    padding-bottom: .5em;
  }
  .repl-help pre code.hljs {
    background-color: transparent;
  }
  </style>
  ~~~
}

\showmd{
  ```?
  im
  ```
}

## Understanding how things work

Each page can be seen as one "notebook".
All executed code blocks on the page are executed in one sandbox module
attached to that page and **share the same scope**.
That sandbox module also loads the content of `utils.jl` as a `Utils` module
and so all objects defined there can be accessed in any code block via
`Utils.$name` (see also [the page on Utils](/syntax/utils/)).

To illustrate the scoping, consider these two consecutive cells:

\showmd{
  ```!
  #hideall
  x = 3;
  ```

  ```!
  y = x
  @show y
  ```
}

When a code block is executed, the code string as well as the output strings are
cached.
This allows for code blocks to not be systematically re-executed if they don't need to be.
The cached representation can however be considered _stale_ in which case the code block
will be re-evaluated as soon as the page changes.
This can be mitigated with the use of `# indep` as [mentioned above](##Marking a cell as independent).
When adding or modifying a code block, every code block below that one are considered stale,
and so will be re-executed.

Since `Utils` is loaded into the sandbox module attached to a page, if `utils.jl` changes,
the entirety of each page's "notebook" will be marked as stale and will be re-run to guarantee
that it uses the latest definitions from `Utils` (even if it doesn't use `Utils` at all).
In that sense changing `utils.jl` amounts to clearing the entire cache and re-building
the website (see also [the page discussing Utils](/syntax/utils/)).


### What to do when things go wrong

While hopefully this shouldn't happen too often, two things can go wrong:

1. some code fails in an un-expected way (e.g.: it calls objects which it should have
  access to but doesn't seem to),
1. the output of an auto-cell is incorrect (either wasn't refreshed or some other random
output that you didn't expect).

In both cases, you can first try to force re-execute the cell and, if that fails, you can
try clearing the cache:

1. to force re-execute a cell, just double the execution marker (e.g. `!!` or `::`),
1. to clear the page cache, interrupt the server, add the [page variable](/syntax/vars+funs/)
  `ignore_cache = true` and re-start the server,
1. to clear the entire site cache, interrupt the server and restart it passing the
argument `clear = true` to `serve(...)` .

In the first case, that cell along with all subsequent cells will be re-evaluated.
In the second case, only the cache associated with the current page will be ignored and only
that page will be (completely) re-evaluated.
In the last case, the whole site is re-built from scratch.

In any case, if you can reproduce what led to the problem, and you think it could be addressed
on the Franklin side,  kindly open an issue on GitHub.

## Output of executable code blocks


When evaluating a code block, Franklin captures `stdout`, `stderr` and, if the code
doesn't fail, the result of the execution.
When using the command `\show` (or automatically if you use implicit naming), the output
is placed in the following HTML:

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

If the code block didn't fail, the _appropriate representation of the result_ is obtained by considering the following cases in order:

1. the result is `nothing`, nothing gets shown (no string),
1. there is a custom `html_show` function for `typeof(result)` that is defined
in your `Utils`, the string returned by the call to that function is then added,
1. the object has a `Base.show` method for `MIME"image/svg+xml"` or `MIME"image/png"`,
the image is automatically saved to an appropriate location and shown (with priority to SVG output),
1. the object has a `Base.show` method for `MIME"text/html"`, it gets called and the HTML gets shown,
1. the object has a `Base.show` method for `MIME"text/plain"`, it gets called and shown in a `<pre><code class="code-result language-plaintext">...</code></pre>` block,
1. otherwise, the fallback `Base.show` is called and shown as in the previous point in a `<pre><code...` block.

Note that you can always suppress the display of a code block result by
adding a final '`;`' to the code.
These different cases are illustrated further below.

\note{
  When capturing `stdout` during a code-cell evaluation, the logging level is
  such that `@info` and `@warn` won't show up.
  This is to prevent getting spurious information being shown on your website from
  packages precompiling upon CI deployment. \\
  Long story short: avoid using these macros in your code cells.
}

You can also overwrite the `\show` command by defining a custom
`lx_show` function in your utils (see [how to define latex commands](/syntax/utils/)) if you
want to handle the output in your own way (or define your own alternative command that does it).


### Nothing to show

Nothing will be shown beyond `stdout` if

* the last command in the code block is a `@show` or returns `nothing`
* the last command in the code block is followed by '`;`'

A few examples follow:

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

\showmd{
  ```!
  function foo()::Nothing
      println("bar")
      return
  end
  foo()    # ==> returns nothing
  ```
}

### Default show

For a result that does not have a custom show, is not showable as an image, or HTML,
`Base.show` will be applied with a result similar to what you would get in the Julia REPL:

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

One exception to this is if the result has a dedicated show method for `MIME"text/plain"` in which
case that is what will be called and shown.


### Showable as SVG or PNG

If the result is showable as SVG or PNG then a relevant file (`.svg` or `.png`) is
generated and the image is inserted with

```html
<img class="code-figure" src="...generated_path_to_img...">
```

~~~
<!-- Avoiding snoopcompile stuff -->
<style>
.fig-stdout {height:0; visibility: hidden}
</style>
~~~


For instance:

\showmd{
  ```!
  # indep
  using Colors
  colorant"cornflowerblue"
  ```
}

If you inspect the HTML, you will see that the image displayed corresponds to a generated path that looks like

```plaintext
/assets/syntax/code/figs-html/__autofig_1682931969501726440.svg
```

The generated path is built as

```plaintext
/assets/[relative-path]/figs-html/[gen]
```

where `relative-path` is the relative path to the page with the code and
`gen` is built out of the hash of the code that generated the image:

```!
hash("""
  using Colors
  colorant"cornflowerblue"
  """ |> strip
  ) |> string
```


Here's another example with Gaston (and you could use any other plotting library such as
[Plots](https://github.com/JuliaPlots/Plots.jl), [PlotlyJS](https://github.com/JuliaPlots/PlotlyJS.jl), etc., though you'll have to be careful about setting dependencies properly.
Check out the [page dedicated to plots with Franklin](/extras/plots/) for more informations.

```!
# name: gaston
# indep
using Gaston
set(term="svg")
x = range(0, pi, length=350)
z = 0.2 * randn(length(x))
y = @. sin(exp(x)) * sinc(x) + z
plot(x, y)
```

\note{
  In order to show properly, the last object needs to be showable. With some
  libraries such as PyPlot this requires an additional command to retrieve the
  showable object (`gcf()` for PyPlot will return the figure which is showable).
}


### HTML show

Some packages define objects which indicate how to show objects with a `MIME"text/html"`,
in that case the corresponding `show` method is called and the HTML shown.
This is for instance the case with DataFrame objects:

```!
# indep
using DataFrames
df = DataFrame(
  (
    names  = ["Vlad", "Martha", "Hasan", "Carl"],
    age    = [50, 34, 23, 42],
    gender = ["M", "F", "M", "M"]
  )
)
```
\lskip

### Custom show

If you have defined a custom `html_show(r)` in your `Utils` that accepts an object of the type
of the result of a code block and returns a string, then that will be used to represent the
result on the page.

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
  Remember that you can refer to any object defined in `utils.jl` with the syntax `Utils.$name_of_object`.
}
\lskip

### Showing the output as Markdown/HTML

In some cases it can be convenient to use a code block to generate some markdown (resp. HTML).
One way is to define a [utils function](/syntax/utils/) but you can also use the `\mdshow` (resp. `\htmlshow`) command
which interprets the output of `stdout` and the string representation of the result as Markdown.

Here's a simple illustration:

\showmd{
  ````!ex-mdshow
  #hideall
  println("```plaintext")
  for i in 1:5
    println("*"^i)
  end
  println("```")
  ````

  \mdshow{ex-mdshow}
}

Here's another one with `\htmlshow`:

\showmd{
  ```!ex-htmlshow
  #hideall
  println("<ul>")
  for i in 1:5
    println("<li>", "🌴"^i, "</li>")
  end
  println("</ul>")
  ```
  \htmlshow{ex-htmlshow}
}



### What if the code errors?

If there's an error in the code, no result will be shown and `stderr` will
capture a trimmed stacktrace of the problem which will be displayed:

\showmd{
  ```!
  # name: error
  # indep
  sqrt(-1)
  ```
}
\lskip

### In what path does the code run?

In the same path as where `serve` was called.
And since you can call `serve()` from within the site folder or from elsewhere specifying
`serve("path/to/folder")`, this path can vary.
As a consequence, if you want some code to do something with a path (e.g. read or write a file),
you should use `Utils.path(:folder)` as the base path pointing to your website folder.

You can also use `Utils.path(:site)` as the base path pointing to the website build folder.

\tip{
  Out of convenience, you can also use `folderpath(...)` as
  shorthand for `joinpath(Utils.path(:folder), ...)` (and, correspondingly,
  `sitepath(...)`).
}

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
  as your base path and use `joinpath` to point to the specific location you care about.
}

[Next page](/syntax/code-2/)
