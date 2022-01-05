+++
showtoc = true
header = "Markdown extensions"
menu_title = "Extensions"
+++

## Equations

In Franklin math is handled by [KaTeX] by default (though you could set things
up so that it's handled by [MathJax] instead).
For _inline_ math, use single `$`:

\showmd{
  The variables $x, y \in \mathbb R$ are  such that $x^2+y^2 = 1$.
}

For _display_ math, use double `$$`:

\showmd{
  Here's a nice equation:

  $$ \exp(i\pi) + 1 = 0 $$
}

Every "display math" block gets automatically numbered.
You can suppress this using `\nonumber{$$...$$}` for instance:

\showmd{
  \nonumber{
    $$ x = 0 $$
  }
}

You can add labels to equations using `\label{label name}` and refer to it via `\eqref{label name}`:

\showmd{
  $$
    x + \underbrace{y + z}_{w} = u \label{some equation}
  $$

  And refer to it as \eqref{some equation}.
}

Equations can span multiple lines and use multi-line environments

\showmd{
  Here's an optimisation problem

  $$
    \text{arg}\,\min_{x\in[0,1]} \,\, f(x)
      \quad\text{s.t.}\quad f(x) =
    \begin{cases}
      x\sin(x^2) \,\,\text{if}\,\, x \in [0, \pi]\\
      x\cos(x^2) \,\, \text{elswhere}
    \end{cases}
  $$

}

Like in LaTeX, you can define [commands](#latex_commands) and use them in a math
environment too (like in LaTeX, commands have to be defined before they're used):

\showmd{
  \newcommand{\E}[1]{\mathbb E\left\{#1\right\}}

  $$ \E{\sum_{i=1}^n X^2_i} = \lambda\exp(\sigma) $$
}

### Styling

The standard styling for KaTeX with Franklin will be something like

```css
body { counter-reset: eqnum; }

.katex { font-size: 1.1em !important; }

.katex-display .katex {
    display: inline-block;
}

.katex-display::after {
    counter-increment: eqnum;
    content: "(" counter(eqnum) ")";
    position: relative;
    float: right;
    padding-right: 5px; }

.nonumber .katex-display::after {
  counter-increment: nothing;
  content: "";
}
```

Increase the `1.1em` to e.g. `1.2em` if you want larger font or decrease to e.g. `1.0em` for smaller font.
The classes `.katex-display` are for block maths, `eqnum` is the CSS counter used for numbering equations.
The `.nonumber` class is used for equations with suppressed numbering.

\note{
  Franklin uses its own counter to keep track of equations, there is no communication between KaTeX or the CSS and Franklin. This also means that you cannot effectively use KaTeX commands that would suppress numbering as this would impact equation references via `\eqref`.
}



## Div blocks

Franklin uses the syntax `@@c1,c2 ... @@` to indicate a div block with class `c1` and `c2`.
This can be useful if you want to style some specific parts of a page, it's also useful when you're working with a class-heavy framework such as Bootstrap.
The classes must be styled in your website CSS. Here's an example with a class `yellow-bg` and a class `red-text` with the following CSS:

```css
.yellow-bg  {background-color: yellow; width: 50%;}
.red-text {color: red;}
```

 ~~~
 <style>
 .yellow-bg  {background-color: yellow; width: 50%;}
 .red-text {color: red;}
 </style>
 ~~~

\showmd{
  @@yellow-bg
    this will be in a box with yellow background
  @@

  @@yellow-bg,red-text
    in a box with yellow background and red text
  @@
}


## LaTeX-like commands

When writing blog posts or lecture notes for instance, you might end up having to repeatedly use some styling, or some sequence of commands, or some sentence.
Franklin allows you to define LaTeX-like commands in much the same way as in LaTeX with the syntax

```plaintext
\newcommand{\command}[nargs]{definition}
```

where `nargs` is the number of arguments of the command and the definition is any valid Franklin markdown with `#1`, `#2`, ... indicating where arguments must be placed.
Examples will make all this much clearer.

First, the case without arguments:

\showmd{
  \newcommand{\command_a}{a sentence that would be repeated many times}

  And here: \command_a
}

Then a case with a single argument:

\showmd{
  \newcommand{\warning}[1]{@@yellow-bg,red-text #1 @@}

  And here: \warning{some important text}
}

Finally a case with two arguments (there can be more, of course, but most often such commands tend to have $\le 2$ arguments):

\showmd{
  \newcommand{\theorem}[2]{**Theorem (#1)**. #2}

  \theorem{Schwarz}{
    $$ (\mathbb E(XY))^2 \le \mathbb E(X^2) \mathbb E(Y^2). $$
  }
}

\tip{
  Command names cannot contain a space or end with either `*` or `_`. But they can end with one or more digits. For instance, `\com1b`, `\com1` or  `\com_a` are allowed but not `\com*` or `\com_` to avoid ambiguities with emphasised text.
}

### Whitespaces

In math environments, to  avoid issues with chaining Franklin-defined commands (which require braces for arguments) and KaTeX commands (which don't always require braces), Franklin forces the insertion of whitespaces left of injected arguments.
This will usually not have a visible effect on the result but you may still want to switch this off, in which case use `!#` in defining the command instead of just `#`.

This is best seen with an example:

\showmd{
  \newcommand{\E}[1]{\mathbb E\left[#1\right]}

  Zero expected-value: $\E{X}=0$.
}

Upon inspection of the generated HTML, you would see:

```html
Zero expected-value: \(\mathbb E\left[ X\right]=0\).
```

Note  how there's  a  whitespace between the inserted `X` and the `[`.
If you had  instead used `!#1` in the definition of the command, that  whitespace would not be there:

\showmd{
  \newcommand{\E}[1]{\mathbb E\left[!#1\right]}

  Zero expected-value: $\E{X}=0$.
}

Observe that there's no visible difference in the result except that the HTML now is:

```html
Zero expected-value: \(\mathbb E\left[X\right]=0\).
```

without whitespace on the left of the `X`.

\tip{
  Generally you should not have to bother with this and can just ignore the `!#` case (in fact KaTeX does some processing of its own to avoid issues with whitespaces).
}

### Defining commands with Julia

You can also define the behaviour of a LaTeX-like command with Julia code.
This can be useful for more advanced processing and is
covered on [a dedicated page](/syntax/utils/).


## LaTeX-like environments

To accompany LaTeX-like commands, you can also define LaTeX-like environments in Franklin which allow defining a custom behaviour for a block of text.
The general syntax is

```plaintext
\newenvironment{name}[nargs]{pre}{post}
```

where `pre` and `post` are inserted before and after the content and can have one or more `#...` to refer to arguments.

Here's an example styling a block and using [raw HTML](#raw_html).

\showmd{
  \newcommand{\html}[1]{~~~#1~~~}
  \newenvironment{style}[1]{
    \html{<div style="#1">}
  }{
    \html{</div>}
  }

  \begin{style}{font-weight: 600; color: blue}
    Here some text
  \end{style}
}

### Defining environments with Julia

Same as with commands, you can also define the behaviour of a LaTeX-like environment
with Julia code. See [here](/syntax/utils/).

## Footnotes

You can add footnotes like you would a reference link except the reference must start with  a caret `^` so for instance `[^1]` or `[^note about x]`.
Footnotes get automatically numbered by order of appearance on the page.
The "definition" of the footnote can be placed wherever is convenient in the Markdown.
On the page however, they will be placed at the end in the order in which they appear.

\showmd{
  Some point we want to add a note to.[^a note]

  [^a note]: did you know about this?
}

The numbering is automatic, irrelevant of whether the footnote id has a number in it or not:

\showmd{
  Some other point worth adding a footnote to.[^1]

  [^1]: how about this? This one is a very long note
  so that you can see how that works, it also has
  some $x$ maths and `foo() = 5` code.
}

Click on  one  of the footnote  link or check the [bottom of this page](#fn-defs) to see the footnotes.

### Styling (XXX)

\todo{explain how to place stuff if not at bottom?}

## Tables (XXX)

\showmd{
  | item | count | price |
  | ---- | ----- | ----- |
  | apple | 5 | 3 |
  | pear | 10 | 5 |
}

\cmdiff{
  For tables, Franklin is stricter than  most Markdown-flavours: valid table rows **must** start
  and end with a `|` and must be entirely defined on a  single line.
}

Any **inline** element is allowed within table cells:

\showmd{
  | A | B |
  | - | - |
  | `x` | $0$ |
  | `y` | $1$ |
}

\showmd{
  | Language | Logo |
  | -------- | ---- |
  | Julia | ![](/assets/julia_icon_small.png) |
  | Python | ![](/assets/python_icon_small.png) |
}

By default content is left-aligned in columns, you can change this by adding a colon (`:`)
on a side to indicate left or right alignment or two colons to indicate centered content:

\showmd{
  | Left (implicit) | Left (explicit) | Center | Right |
  | --------------- | :-------------- | :----: | ----: |
  | ABC | ABC | ABC | ABC |
  | DEF | DEF | DEF | DEF |
  | GHI | GHI | GHI | GHI |
}

### Styling

A generated table will have the following HTML structure:

```html
<table class="{{table_class}}">
  <thead>
    <th> Header column 1 </th>
    <th> Header column 2 </th>
    ...
  </thead>
  <tbody>
    <tr>                  <!-- first row -->
      <td> content </td>  <!-- first column -->
      <td> ... </td>
      ...
    </tr>
    ...
  </tbody>
</table>
```

The `table_class` is a page variable that you can specify and which is empty by default.
This can be useful if you're using a CSS framework like [Pure][pure.css] which have specific
classes for tables with good defaults (here, for instance, we're using
[`pure-table`](https://purecss.io/tables/) as the class).

If you're not using a framework, you will want to style the elements `table`, `thead`, `th`,
`tbody`, `tr` and `td` as desired.
CSS tricks has a [nice article](https://css-tricks.com/complete-guide-table-element/) on
styling tables.


## Raw HTML

You can insert arbitrary HTML in Franklin using the syntax `~~~ ... ~~~` replacing  `...` with  any valid HTML including  Franklin-specific HTML extensions (h-funs).

\showmd{
  ABC ~~~<span style="color:blue;">~~~ **DEF** ~~~</span>~~~ GHI.
}
\showmd{
  ~~~
  <fieldset><legend>Foo</legend>
  Some Content
  </fieldset>
  ~~~
}

Since you can  wrap this in a command,  you can define commands that apply whatever custom HTML you see  fit,  or use this to  insert  buttons  etc.

## Raw content

For both HTML and LaTeX output, raw content allows to pass some content completely untouched to the final  stage of the processing (either the web-browser or the  LaTeX compiler) without Franklin  interfering.
For those,  use `??? ... ???`:

\showmd{
  1. ABC **DEF** GHI (converted  by Franklin)
  1. ??? ABC **DEF** GHI ??? (untouched by Franklin)
}
