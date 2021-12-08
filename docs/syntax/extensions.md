+++
showtoc = true
header = "Markdown extensions"
+++

## Maths

In Franklin maths is handled by [KaTeX](https://katex.org) by default (though you could set things up so that it's handled by MathJax instead).
For _inline_ maths, use single `$`:

\showmd{
  The variables $x, y \in \mathbb R$ are  such that $x^2+y^2 = 1$.
}

For _display_ maths, use double `$$`:

\showmd{
  Here's a nice equation:

  $$ \exp(i\pi) + 1 = 0 $$
}

equations can span multiple lines and use multi-line environments

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

Like in LaTeX, you can define [commands](#latex_commands) and use them in a math environment too (like in LaTeX, commands have to be defined before they're used):

\showmd{
  \newcommand{\E}[1]{\mathbb E\left\{#1\right\}}

  $$ \E{\sum_{i=1}^n X^2_i} = \lambda\exp(\sigma) $$
}

### Styling (XXX)

- numbering (look up new stuff, there's a counter set by KaTeX now)
- text size

## Div Blocks

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

where `nargs` is the number or "arguments" of the command and the definition is any valid Franklin markdown with `#1`, `#2`, ... indicating where arguments must be placed.
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
  Command names cannot contain a space, end with a `*` or a `_`. But they can end with one or more digits. For instance, `\com1b`, `\com1` or  `\com_a` are allowed but not `\com*` or `\com_` to avoid ambiguities with indicators for emphasis.
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
  Generally you should not have to bother about this and can just ignore the `!#` case (in fact KaTeX does some processing of its own to avoid issues with whitespaces).
}



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

## Footnotes

You can add footnotes like you would a reference link except the reference must start with  a caret `^` so for instance `[^1]` or `[^note about x]`.
Footnotes get automatically numbered by order of appearance on the page.
The "definition" of the footnote can be placed wherever is convenient in the Markdown.
On the page, however, they will be placed at the end in the order in which they appear.

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

## Tables

\showmd{
  | item | count | price |
  | ---- | ----- | ----- |
  | apple | 5 | 3 |
  | pear | 10 | 5 |
}

\cmdiff{
  Franklin is stricter than  most Markdown-flavours in how it supports tables: valid table rows **must** start and end with a `|` and must be entirely defined  on a  single line.
}

Any **inline** element is allowed within table cells:

\showmd{
  | A | B |
  | - | - |
  | `x` | $0$ |
  | `y` | $1$ |
}


### Styling (XXX)

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