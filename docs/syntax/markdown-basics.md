# Markdown basics

{{rm_headers level_1 level_2 level_3}}
\toc

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
  \* \_ \$ \` \@ \# \{ \} \~ \! \% \& \' \+ \, \- \. \/ \: \; \< \= \> \? \^ \|
}

## Paragraphs

When converting text (to HTML or LaTeX), sets of consecutive "inline" blocks will be grouped and placed within a paragraph (in HTML: `<p>...</p>`).
Inline blocks can be:

* text not separated by an empty line
* inline code
* inline math
* special characters
* latex-like commands
* ...

A paragraph will be interrupted by:

* a line skip,
* a "non-inline" block (for instance a heading or a code block),
* the end of the text.

If you want to introduce a line return without interrupting a paragraph, you can use a double backslash `\\` (similar to LaTeX):

\showmd{
  ABC \\ DEF
}

## Headings

Headings are created with one or more `#` followed by a space and the heading title.
There can be up to 6 `#` indicating the depth of the title though note that only 3 levels are supported in the LaTeX conversion:

\showmd{
  # Level 1
  ## Level 2
  ### Level 3
}

Headings are automatically made into anchors (including the ones above).
This allows to easily link to parts of a page (and also across pages).
For instance `[link](#headings)` will give: [link](#headings).

\cmdiff{
  CommonMark supports indicating level 1 and 2 headings by underlying them with `===` or `---`; this is not supported in Franklin.  
}

## Blockquotes

A set of lines prefixed with `>` will form a blockquote as well as lines immediately after not separated by an empty line (continuation lines):

\showmd{

  > ABC
  > DEF
  GHI (continuation, still part of quote)
  JKL (also)

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


## (XXX) Lists

\showmd{
  * Apples
  * Oranges
  * Pears
    * Bosc
    * Bartlett
}

\showmd{
  1. Apples
  1. Oranges
  1. Pears
    1. Bosc
    1. Bartlett
}

## (XXX) Links

**TODO**: indicate that only AB and A links are allowed and that's it.

\showmd{
  * [JuliaLang website](https://julialang.org)
  * [julialang]

  [julialang]: https://julialang.org
}

## (XXX) Images

\showmd{
  ![alt](/assets/rndimg.jpg)
  ![iguana]

  [iguana]: /assets/rndimg.jpg
}

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

## (XXX) HTML

### Raw HTML

### HTML entities
