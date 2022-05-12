<!--
LAST REVISION:
 -->


+++
showtoc = true
header = "Code blocks (2)"
menu_title = header
+++

## Using packages

As already illustrated in a few examples on the [previous page](/syntax/code/), you can use packages in executable code blocks.
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

## Environments

It can be convenient to activate a specific environment for the code to be executed on a page.
The `\activate{some/path/}` command allows you to specify a (unix-style) relative path to the website folder where a specific `Project.toml` file resides.
Effectvely this will have the same effect as calling `Pkg.activate(...)` inside a code-cell.

If you leave the path empty or just use a single `.` (`\activate{}` or `\activate{.}`), Franklin will try to activate the directory that contains the page being currently built.

All evaluated code cells following the `activate` command will be executed in the relevant environment.
Whenever a page build is finished, the "parent" environment is re-activated (this would correspond to the website folder environment if there's a `Project.toml` file there, or just the Main environment otherwise).

For instance in the following scenario:

```
website
├── A
│   ├── Project.toml
│   └── index.md
├── B
│   ├── Project.toml
│   └── index.md
├── Project.toml
├── _layout
├── ...
└── index.md
```

you might have both `website/A/index.md` and `website/B/index.md` the command `\activate{.}`, which will activate respectively `website/A/Project.toml` and `website/B/Project.toml`.
Once either `A` or `B` has finished building, the main environment at `website/Project.toml` will be re-activated.


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
  <!-- Command to show and execute python code -->
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

  <!-- Example with pandas -->
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
  the Python environment it uses has the relevant libraries (e.g. `numpy` or `pandas`).
}
