+++
showtoc = true
header = "Markdown basics"
+++

<!-- avoid having the dummy example headers in the toc -->
{{rm_headers level_1 level_2 level_3}}

## Text Emphasis

You can surround words with `*` to change the text emphasis (bold, italic):

\showmd{
  *italic* **bold** ***bold+italic***
}

this also works with `_`:

\showmd{
    _italic_ __bold__ ___bold+italic___
}

and you can nest emphasis styles:

\showmd{
  _italic **bold+italic**_
}

If you want to show the characters `*` or `_` (or other special characters which have a meaning in Franklin), you should escape them with a `\ `:


\showmd{
  \* \_ \$ \` \@ \# \{ \} \~ \! \% \& \'    \\
  \+ \, \- \. \/ \: \; \< \= \> \? \^ \|
}

The double backslash, like in LaTeX, works as a line break as clarified below.

## Paragraphs

When converting text (to HTML or LaTeX), sets of consecutive "inline" blocks will be grouped
and placed within a paragraph (in HTML: `<p>...</p>`).
Inline blocks can be:

* text not separated by an empty line
* inline code
* inline maths
* special characters
* latex-like commands
* ...

A paragraph will be interrupted by:

* a line skip,
* a "non-inline" block (for instance a heading or a code block),
* the end of the text.

If you want to introduce a line return without interrupting a paragraph,
you can use a double backslash `\\` (similar to LaTeX):

\showmd{
  ABC \\ DEF
}

## Headings

You can indicate headings with one or more adjacent `#` followed by a space and
the heading title. There can be up to 6 `#` indicating the depth of the title
though note that only 3 levels are supported in the LaTeX conversion:

\showmd{
  # Level 1
  ## Level 2
  ### Level 3
}

Headings are automatically made into anchors (you can see this by hovering
over the ones created above).
This allows to easily link to parts of a page (as well as across pages).
For instance `[link](#headings)` will give: [link](#headings).
See also the section on [Links](#links) below.

\cmdiff{
  CommonMark supports indicating level 1 and 2 headings by underlying them
  with `===` or `---` (_alt heading_) this is not supported in Franklin.  
}

## Blockquotes

A set of lines prefixed with `>` will form a blockquote as well as lines
immediately after not separated by an empty line (continuation lines):

\showmd{

  > This is a blockquote,
  > this line is in the same blockquote,
  and this one (continuation, still part of quote),
  and this one (idem)

  Here it's separate as there's a line skip.
}

there can be any formatting in the blockquote:

\showmd{
  > ABC
  > DEF **GHI**

}

you can also skip lines which will act as a paragraph break _within_ the blockquote:

\showmd{
  > ABC
  >
  > GHI

}

you can also nest blockquotes (make sure you skip a line after the nested block as shown below to separate between the inner nested quote and the outer one):

\showmd{
  > ABC
  > > DEF
  > > GHI
  >
  > JKL

}


## Lists

Lists are formed of one or more items indicated with a line starting with a `*`, `-` or `+`
(un-ordered list) or a number followed by a dot (`.`) or a bracket (`)`) (ordered list).
Nesting is indicated with either a tab or two or more spaces.

Here's a simple un-ordered list:

\showmd{
  * Apples
  * Oranges, note that list item can be continued on
  another line, that's fine as long as there's no line-skip
  * Pears
    * Bosc
    * Bartlett
}

Here's a simple ordered list with an un-ordered nested list
(note that after the first item indicator, the numbering is automatic
and so we can use the same number multiple times):

\showmd{
  1. Apples
  1. Oranges (the indicator for the second item onwards is ignored)
  1. Pears
    + Bosc
    + Bartlett
}

the number of the first item of an ordered list indicates the starting number
which can be different than 1:

\showmd{
  2. Foo
  1) Bar
  1. Baz
}

List items can contain any "inline" item (e.g. emphasised text or maths):

\showmd{
  * variables $x, y$ and $z$ are _reals_,
  * variables $i, j$ and $k$ are _integers_,
  * the function `foo` does not have side-effects.
}

\cmdiff{
  "Loose" lists (with line skips between items) are not supported in Franklin.
}

## Links

You can insert a link by writing `[link title](link_url)`.
For instance this is a link pointing to the Julia Lang website:

\showmd{
  [JuliaLang website](https://julialang.org)
}

It can be convenient to link multiple times to the same location in which case you
can define a reference by writing `[Name Of Reference]: location` on a dedicated
line and use the reference by specifying `[Name Of Reference]` somewhere in the text:

\showmd{
  [JuliaLang]: https://julialang.org
  [Wikipedia]: https://wikipedia.org

  Text pointing to [JuliaLang] and [Wikipedia] and here's a second one to
  [JuliaLang].
}

The pointer to a reference can be placed before or after the reference.
The id of the reference can have spaces in it (and case doesn't matter).
The main constraint is that the reference definition must be on a dedicated line.
Here's another example:

\showmd{
  Here's text and a link to [the JuliaLang Website].

  [the julialang website]: https://julialang.org
}

You could also change the title to an existing reference by writing
`[link title][the reference]`:

\showmd{
  [euler]: https://projecteuler.net/

  These all point to the same location:
  * [Project Euler][euler],
  * [The Project Euler][euler],
  * [euler].
}

\tip{
  You might want to define references that can be used on all your pages.
  To do so, just place the reference definition on a line in your `config.md` file.
  For instance [this reference][juliaweb] is defined in the current config file.
}


You might also sometimes want the link to appear as the location itself.
For this, you can use the _autolink_ syntax `<location>`:

\showmd{
  Link to the JuliaLang website: <https://julialang.org>.
}

\cmdiff{
  CommonMark allows a few other variants such as `[link](location "title")` or
  references with `[name]: location "title"`.
  These are not supported in Franklin.
}

## (XXX) Images

<!-- XXX -->

<!-- \showmd{
  ![alt](/assets/rndimg.jpg)
  ![iguana]

  [iguana]: /assets/rndimg.jpg
} -->

## (XXX) Code

\showmd{
  Inline code: `abc`
}

\showmd{
  ```julia
  function foo(x::Int)
    println("hello"^x)
  end
  ```
}

\showmd{
  ````markdown
  ```julia
  abstract type Foo end
  ```
  ````
}

**TODO** link to executable code blocks

## (XXX) Horizontal rules

If a line contains exclusively 3 or more consecutive of either `-`, `*` or `_`, a
horizontal rule will be inserted:

\showmd{
  ABC
  ---
  DEF
  ***
  GHI
  ___
}

if the same character (e.g. `-`) is present after that on the line, the effect will be the same:

\showmd{
  --- --- --- - -- --- ------
  **** *
  ___________________________
}

## (XXX) HTML

### Raw HTML

### HTML entities
