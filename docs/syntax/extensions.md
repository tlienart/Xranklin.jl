<!--
LAST REVISION: Jan 20, 2022  (full page ok)
 -->

+++
showtoc = true
header = "Markdown extensions"
menu_title = "Extensions"
+++

## Overview

Franklin adds a number of extension to the Markdown-like syntax in order to
facilitate some operations such as adding [equations](#equations), [tables](#tables),
[footnotes](#footnotes), [commands](#latex_like_commands) and more.

## Injecting HTML

You can always insert arbitrary HTML on a page in a block fenced with '`~~~`'.
HTML inserted in this way is considered "inline" (it won't break an existing paragraph).
Here's an example where we apply some local styling inside a paragraph:

\showmd{
  ABC ~~~<span style="color:blue;">~~~ **DEF** ~~~</span>~~~ GHI.
}

Here's another example where we insert a `<fieldset>`:

\showmd{
  ~~~
  <fieldset><legend>Foo</legend>
  Some Content
  </fieldset>
  ~~~
}

Since you can  wrap this in a [LaTeX-like command](#latex_like_commands), you can define commands
that apply whatever custom HTML you see  fit, or use this to insert buttons etc.

## Equations

In Franklin, math is handled by [KaTeX] (though you could set things
up so that it's handled by [MathJax] instead).
For _inline_ math, use a single '`$`' like in LaTeX (here's a [cheatsheet](http://tug.ctan.org/info/undergradmath/undergradmath.pdf) for LaTeX math if you're unfamiliar with the syntax):

\showmd{
  The variables $x, y \in \mathbb R$ are  such that $x^2+y^2 = 1$.
}

For _display_ math, use double '`$$`':

\showmd{
  Here's a nice equation:

  $$ \exp(i\pi) + 1 = 0 $$
}

"Display math" blocks get automatically numbered.
You can suppress this using `\nonumber{$$...$$}`.
For instance:

\showmd{
  \nonumber{
    $$ x = 0 $$
  }
}

You can add labels to display-math blocks using `\label{label name}` and refer to them
later with `\eqref{label name}`:

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
environment too:

\showmd{
  \newcommand{\E}[1]{\mathbb E\left\{#1\right\}}

  $$ \E{\sum_{i=1}^n X^2_i} = \lambda\exp(\sigma) $$
}

\note{
  Double-braces (which can be used to call [hfuns](/syntax/vars+funs/) or insert page variables)
  are disabled in math environments.
  This is to avoid ambiguities since in LaTeX-like math syntax,
  double braces can happen. So, for instance, `${{x}}$` will just show $x$ even if you do have
  a page variable `x` on the page.
}

\note{
  Franklin uses its **own counter** to keep track of equation numbering.
  There is no communication between Franklin and any KaTeX or CSS counters.
  This means that you cannot effectively use KaTeX-specific commands that suppress numbering
  as this would cause issues with subsequent equation references done with `\eqref`.\\
  Long story short: if you want to suppress numbering, use `\nonumber`.
}


### Environments

Franklin also supports common math environments: `equation`, `align`, `aligned`, `eqnarray`,
and their "starred" version (which suppresses the number):

\showmd{
  \begin{eqnarray*}
    \mathcal F[g](\omega)
            &=& \langle g, \exp(i\omega \cdot) \rangle \\
            &=& \displaystyle{\int_{\mathbb R} g(x)\exp(i\omega x)\mathrm{d}x}
  \end{eqnarray*}
}

\note{
  In "proper" LaTeX, the use of `\eqnarray` is discouraged due to possible interference
  with array column spacing.
  In Franklin/KaTeX this does not happen and so the only practical difference is that
  `\eqnarray` will give you a bit more horizontal spacing around the `=` signs than
  the `align` environme
  nt.
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
The class `.katex-display` is for block math, `eqnum` is the CSS counter used for numbering equations.
The `.nonumber` class is used for equations with suppressed numbering.

## Tables

Franklin supports inserting tables with the following syntax:


\showmd{
  | item | count | price |
  | ---- | ----- | ----- |
  | apple | 5 | 3 |
  | pear | 10 | 5 |
}

Table rows **must** start **and** end with a '`|`' symbol and **must** be entirely defined
on a single line (this is a bit stricter than what most Markdown flavour that support table
  require).
Observe that alignment of the '`|`' is not necessary (though it often helps readability!)
and spaces around '`|`' are insignificant.
If a row is found to have too many or too few cells, the table will be padded accordingly:

\showmd{
  | A | B | C |
  | - | - | - |
  | 1 |
  | 1 | 2 |
  | 1 | 2 | 3 |
  | 1 | 2 | 3 | 4 |  
}

Any **inline** element is allowed within table cells and header cells:

\showmd{
  | A | B |
  | - | - |
  | `x|y` | $x \in \mathbb R$ |
}

Images are also inline blocks and so can be inserted in cells as well:

\showmd{
  | Language | Logo |
  | -------- | ---- |
  | Julia | ![](/assets/icons/julia_icon_small.png) |
  | Python | ![](/assets/icons/python_icon_small.png) |
}

By default content is left-aligned in columns.
You can change this by using `:-` (left) or `:--:` (center) or `-:` (right)
under the relevant column header:

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

The `table_class` is a [page variable](/syntax/vars+funs/) that you can specify,
and which is empty by default.
This can be useful if you're using a CSS framework like [Pure][pure.css] which has specific
classes for tables with good defaults (here, for instance, we're using
[`pure-table`](https://purecss.io/tables/) as the class).

If you're not using a framework, you will want to style the elements `table`, `thead`, `th`,
`tbody`, `tr` and `td` as desired.
CSS tricks has a [nice article](https://css-tricks.com/complete-guide-table-element/) on
styling tables.



## Footnotes

You can add footnotes like you would a [reference link](/syntax/basics/#links) except
that the reference must start with a caret '`^`' so for instance `[^1]` or
`[^note about x]`.
Footnotes get automatically numbered by order of appearance on the page.
The "definition" of the footnote can be placed wherever is convenient in the Markdown.
On the page however, they will be placed at the end of the page in the order in which
they appeared.

\showmd{
  Some point we want to add a note to.[^a note]

  [^a note]: did you know about this?
}

The numbering is automatic, irrelevant of whether the footnote id has a number in it or not:

\showmd{
  Some other point worth adding a footnote to.[^1]

  [^1]: how about this? This one is a very long note
  so that you can see how that works, it also has
  some $x$ math and `foo() = 5` code.
}

Click on  one  of the footnote  link or check the [bottom of this page](#fn-defs)
to see the footnotes.

The list of footnotes will be placed wherever you put a `{{footnotes}}`.
Typically (like here), this is part of the layout in `_layout/foot.html`,
but you could choose to place it manually.

You can also use `{{footnotes 1 2 "note abc"}}` to list only a few notes in a
given spot.


## Div blocks

It can sometimes be nice to use a specific CSS styling for a part of a page.
For instance you might want to have some text that's in a different font, or a different colour,
or that is centred.
You can of course always achieve this by injecting [raw HTML](#injecting_html) directly,
another way is to use `@@c1,c2 ... @@` to indicate a **div block** with class `c1` and `c2`.

This is particularly useful when you're working with a class-heavy framework such as [Bootstrap].
Here's an example with a class `yellow-bg` and a class `red-text` with the following CSS:

```css
.yellow-bg  {background-color: yellow; width: 50%; padding-left: 2em;}
.red-text {color: red;}
```

 ~~~
 <style>
 .yellow-bg  {background-color: yellow; width: 50%; padding-left: 2em;}
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

When writing blog posts or lecture notes for instance, you might end up having to repeatedly
use some styling, or some sequence of commands, or some sentence.
To help you with this, Franklin supports defining LaTeX-like commands in much the same way
as in LaTeX with the syntax

```plaintext
\newcommand{\command}[nargs]{definition}
```

where `nargs` is the number of arguments of the command and the definition is any valid Franklin markdown with `#1`, `#2`, ... indicating where arguments must be placed.
Examples will make all this much clearer.

First, the case without arguments:

\showmd{
  \newcommand{\command_a}{_a sentence that would be repeated many times_}

  And here: \command_a
}

Then a case with a single argument:

\showmd{
  \newcommand{\warning}[1]{@@yellow-bg,red-text #1 @@}

  And here: \warning{some important text}
}

Finally a case with two arguments (there can be more, of course, though beyond 2 they become
  harder to read and maintain):

\showmd{
  \newcommand{\theorem}[2]{**Theorem (#1)**. #2}

  \theorem{Schwarz}{
    $$ (\mathbb E(XY))^2 \le \mathbb E(X^2) \mathbb E(Y^2). $$
  }
}

Since command can wrap around raw HTML injection as well, you can for instance define a
command that applies custom local-styling to some text:

\showmd{
  \newcommand{\style}[2]{~~~<span style="#1">~~~#2~~~</span>~~~}

  Here is \style{color:blue}{some text in blue} and
  \style{font-weight:750;font-family:serif;}{some bolder serif text}.
}

\tip{
  Command names cannot contain a space or end with either '`*`' or '`_`'.
  But they can end with one or more digits.
  For instance, `\com1b`, `\com1` or  `\com_a` are allowed but not `\com*` or `\com_`,
  to avoid ambiguities with emphasised text.
}


### Whitespaces

In math environments, to  avoid issues with chaining Franklin-defined commands
(which require braces for arguments) and KaTeX commands (which don't always require braces),
Franklin forces the insertion of whitespaces left of injected arguments.
This will usually not have a visible effect on the result but you may still
want to switch this off.
In this case, use '`!#`' in defining the command instead of just '`#`' when referring to an
argument in a definition.
This is best seen with an example:

\showmd{
  \newcommand{\E}[1]{\mathbb E\left[#1\right]}

  Zero expected-value: $\E{X}=0$.
}

The HTML generated by the above expression is:

```html
Zero expected-value: \(\mathbb E\left[ X\right]=0\).
```

Note  how there's a whitespace between the inserted '`X`' and the '`[`'.
If you had instead used '`!#1`' in the definition of the command, that
whitespace would not be there:

\showmd{
  \newcommand{\E}[1]{\mathbb E\left[!#1\right]}

  Zero expected-value: $\E{X}=0$.
}

Observe that there's no visible difference in the result except that the HTML now is:

```html
Zero expected-value: \(\mathbb E\left[X\right]=0\).
```

without whitespace on the left of the '`X`'.

\tip{
  Generally you should not have to bother with this and can just ignore the `!#` case (in fact KaTeX does some processing of its own to avoid issues with whitespaces).
}


### Defining commands with Julia

You can also define the behaviour of a LaTeX-like command with Julia code.
This can be useful for more advanced processing and is
covered on [a dedicated page](/syntax/utils/).


## LaTeX-like environments

To accompany LaTeX-like commands, you can also define LaTeX-like environments in
Franklin which allow defining a custom behaviour for a block of text.
The general syntax is

```plaintext
\newenvironment{name}[nargs]{pre}{post}
```

where `pre` and `post` are inserted before and after the content and can have
one or more `#...` to refer to the arguments.

Here's an example styling a block and using [raw HTML](#injecting_html).

\showmd{
  \newcommand{\html}[1]{~~~#1~~~}
  \newenvironment{blockstyle}[1]{
    \html{<div style="#1">}
  }{
    \html{</div>}
  }

  \begin{blockstyle}{font-weight: 600; color: blue}
    Here some text
  \end{blockstyle}
}

### Defining environments with Julia

As with commands, you can also define the behaviour of a LaTeX-like environment
with Julia code, this is covered [on a dedicated page](/syntax/utils/).





## Raw content

For both HTML and LaTeX output, raw content allows to pass some content completely untouched to the final  stage of the processing (either the web-browser or the  LaTeX compiler) without Franklin  interfering.
For those,  use `??? ... ???`:

\showmd{
  1. ABC **DEF** GHI (converted  by Franklin)
  1. ??? ABC **DEF** GHI ??? (untouched by Franklin)
}
