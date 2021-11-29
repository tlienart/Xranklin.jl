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

## Div Blocks

## LaTeX commands

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

### Styling (XXX)

## Raw HTML
