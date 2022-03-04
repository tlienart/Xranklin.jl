<!--
LAST REVISION: Jan 14, 2022 (full page ok)
 -->


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

For all these you can also swap the colon ('`:`') with an exclamation mark ('`!`') with
the same effect (see examples below).

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

If a code block is fully independent of any other code blocks on the page, you can mark it as _independent_ (with `# indep`), this will allow Franklin to skip re-evaluating this block when other code blocks around it change.

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

If the code block didn't fail, the _appropriate representation_ of a result that is
not `nothing` is obtained by considering the following cases in order:

1. there is a custom `html_show` function for `typeof(result)` that is defined
in your `Utils`: the string returned by the call to that function is then added,
1. the object can be shown as an SVG or PNG image: the image is automatically saved to
an appropriate location and shown (with priority to the SVG output),
1. the output of `Base.show(result)` is added in a `<pre><code...` block.

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

For a result that is not showable as an image or doesn't have a custom show, `Base.show`
will be applied with a result similar to what you would get in the Julia REPL:

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
  using Luxor
  @drawsvg juliacircles()
  ```
}

If you inspect the HTML, you will see that the image displayed corresponds to a generated path that looks like

```plaintext
/assets/syntax/code/figs-html/__autofig_10012904553771893789.svg
```

The generated path is built as

```plaintext
/assets/[relative-path]/figs-html/[gen]
```

where `relative-path` is the relative path to the page with the code and
`gen` is built out of the hash of the code that generated the image:

```!
hash("""
  using Luxor
  @drawsvg juliacircles()
  """ |> strip
  ) |> string
```


Here's another example with PyPlot (and you could use any other plotting library such as
  [Plots](https://github.com/JuliaPlots/Plots.jl),
  [PlotlyJS](https://github.com/JuliaPlots/PlotlyJS.jl), etc.)

```!
using PyPlot
x = range(0, pi, length=500)
y = @. sin(exp(x)) * sinc(x)
figure(figsize=(6, 4))
plot(x, y)
gcf()
```

Note that it's the figure object that is showable as SVG in Pyplot and so we must do
`gcf()` here to have it be the effective result of the cell and have the plot shown.


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
\lskip

## Using packages

As already illustrated in a few examples above, you can use packages in executable code blocks.
You should make sure that those packages are added to the environment corresponding to the
website folder. For instance let's say you want to use `CSV` and `DataFrames`, you would do:

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

\lskip

### Cache and packages

If you start a new Julia session and have a page where some code uses a package
(say `DataFrames`) and you add a new code block at the end of the page, only that
code will be executed and, therefore, won't have access to `DataFrames` unless
you re-evaluate the whole page **or** you explicitly add `using DataFrames` in that
new cell (possibly with a `# hide` if you don't want to show it multiple times).

Alternatively, you can (same as when you encounter errors):

* set the current page to ignore the cache at the start of the server by setting
the page variable `ignore_cache` to `true` and restart the server,
* clear the entire site cache.

## More examples

You'll find here a few toy examples of what can be done with executed
code cells, hopefully it will give you some inspiration for what you might do with
them yourself!

### Generating a table

In this example we use code to generate the Markdown representation of a table and use
`\mdshow` to show the result.
You could combine such an example with `CSV` to read data from a file for instance.

\showmd{
  ```!ex-gen-table
  #hideall
  names = (:Taimur, :Catherine, :Maria, :Arvind, :Jose, :Minjie)
  numbers = (1525, 5134, 4214, 9019, 8918, 5757)
  # header
  println( "| Name  | Number  |")
  println( "| :---  | :---    |")
  # all rows
  println.("| $name | $number |"
    for (name, number) in zip(names, numbers)
  );
  ```
  \mdshow{ex-gen-table}
}

### Generating SVG

Here we combine the use of `\mdshow` with a command that inputs some SVG.

~~~
<style>
.ccols {
  margin-top:1.5em;
  margin-bottom:1.5em;
  margin-left:auto;
  margin-right:auto;
  width: 60%;
  text-align: center;}
.ccols svg {
  width:30px;}
</style>
~~~


\showmd{
  \newcommand{\circle}[1]{
    ~~~
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 4 4">
    <circle cx="2" cy="2" r="1.5" fill="#1"/></svg>
    ~~~
  }

  ```!ex-gen-svg
  #hideall
  cols = (
    :pink, :lightpink, :hotpink, :deeppink,
    :mediumvioletred, :palevioletred, :coral,
    :tomato, :orangered, :darkorange, :orange, :gold
  )
  print("@@ccols ")
  print.("\\circle{$c}" for c in cols)
  println("@@")
  ```

  \mdshow{ex-gen-svg}
}

The CSS corresponding to `ccols` is

```css
.ccols {
  margin-top:1.5em;
  margin-bottom:1.5em;
  margin-left:auto;
  margin-right:auto;
  width: 60%;
  text-align: center;}
.ccols svg {
  width:30px;}
```

### Team cards

You may want to have a page with responsive team cards for instance where every card would
follow the same layout but the content would be different.
There are multiple ways you can do this with Franklin and a simple one below
(adapted from [this tutorial](https://www.w3schools.com/howto/howto_css_team.asp)).
The advantage of doing something like this is that it can help separate the content
from the layout making both arguably easier to maintain.

~~~
<style>
.column {
  float:left;
  width:30%;
  margin-bottom:16px;
  padding:0 8px; }
@media (max-width:62rem) {
  .column {
    width:45%;
    display:block; }
  }
@media (max-width:30rem){
  .column {
    width:95%;
    display:block;}
  }
.card { box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2); }
.card img {
  padding-left:0;
  width: 100%; }
.container { padding: 0 16px; }
.container::after, .row::after{
  content: "";
  clear: both;
  display: table; }
.title { color: grey; }
.vitae { margin-top: 0.5em; }
.email {
  font-family: courier;
  margin-top: 0.5em;
  margin-bottom: 0.5em; }
.button{
  border: none;
  outline: 0;
  display: inline-block;
  padding: 8px;
  color: white;
  background-color: #000;
  text-align: center;
  cursor: pointer;
  width: 100%; }
.button:hover{ background-color: #555; }
</style>
~~~

\showmd{
  \newcommand{\card}[5]{
    @@card
      ![#1](/assets/eximg/team/!#2.jpg)
      @@container
        ~~~
        <h2>#1</h2>
        ~~~
        @@title #3 @@
        @@vitae #4 @@
        @@email #5 @@
        ~~~
        <p><button class="button">Contact</button></p>
        ~~~
      @@
    @@
  }

  ```!ex-gen-teamcards
  #hideall
  team = [
    (
      name="Jane Doe",
      pic="beth",
      title="CEO & Founder",
      vitae="Phasellus eget enim eu lectus faucibus vestibulum",
      email="example@example.com"
    ),
    (
      name="Mike Ross",
      pic="rick",
      title="Art Director",
      vitae="Phasellus eget enim eu lectus faucibus vestibulum",
      email="example@example.com"
    ),
    (
      name="John Doe",
      pic="meseeks",
      title="Designer",
      vitae="Phasellus eget enim eu lectus faucibus vestibulum",
      email="example@example.com"
    )
  ]

  "@@cards @@row" |> println
  for person in team
    """
    @@column
      \\card{
        $(person.name)}{
        $(person.pic)}{
        $(person.title)}{
        $(person.vitae)}{
        $(person.email)}
    @@
    """ |> println
  end
  println("@@ @@") # end of cards + row
  ```

  \mdshow{ex-gen-teamcards}
}

The CSS used here is

```css
.column {
  float:left;
  width:30%;
  margin-bottom:16px;
  padding:0 8px; }
@media (max-width:62rem) {
  .column {
    width:45%;
    display:block; }
  }
@media (max-width:30rem){
  .column {
    width:95%;
    display:block;}
  }
.card { box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2); }
.card img {
  padding-left:0;
  width: 100%; }
.container { padding: 0 16px; }
.container::after, .row::after{
  content: "";
  clear: both;
  display: table; }
.title { color: grey; }
.vitae { margin-top: 0.5em; }
.email {
  font-family: courier;
  margin-top: 0.5em;
  margin-bottom: 0.5em; }
.button{
  border: none;
  outline: 0;
  display: inline-block;
  padding: 8px;
  color: white;
  background-color: #000;
  text-align: center;
  cursor: pointer;
  width: 100%; }
.button:hover{ background-color: #555; }
```

### Executing Python code

Using [PyCall] you can evaluate Python code in Julia, and so you can do that in Franklin too.
The simple example below shows how that can work (you could do something similar with [RCall] too).

\showmd{
  \newcommand{\pycode}[1]{
    <!-- Show python code block -->
    ```python
    #1
    ```
    <!-- Execute code with PyCall.jl -->
    ```!
    #hideall
    using PyCall
    lines = replace(
      """#1""",
      r"(^|\n)([^\n]+)\n?$" => s"\1res = \2"
    )
    py"""
    $$lines
    """
    println(py"res")
    ```
  }

  \pycode{
    import pandas as pd
    df = pd.DataFrame({
      "A": ["Alice", "Bob", "Jane"],
      "B": [2, 3, 4]
      })
    df["B"].mean()
  }

}

The `replace` line in the code block adds a `res = ...` before the last line
so that the result can be shown, cf. the [PyCall] docs.

\note{
  It's up to you to make sure that [PyCall] works well in your Julia session and that
  the Python environment it uses has the relevant libraries (e.g. `numpy`).
}
