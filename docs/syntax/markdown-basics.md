# Markdown basics

{{rm_headers level_1 level_2 level_3}}
\toc

## Emphasis

You can surround words with `*` to change the emphasis:

\showmd{
  *italic* **bold** ***bold+italic***
}

this also works with `_`:

\showmd{
    _italic_ __bold__ ___bold+italic___
}

these can be nested:

\showmd{
  _italic **bold+italic**_
}

If you want to show the characters `*` or `_` (or other special characters which have a meaning in Franklin), you should escape them with a `\\`:

\showmd{
  \* \_ \$ \` \@ \# \{ \} \~ \! \% \& \' \+ \, \- \. \/ \: \; \< \= \> \? \^ \|
}

## Paragraphs

When converting markdown, a set of consecutive "inline" blocks will be converted and placed within a paragraph (`<p>...</p>`).
Inline blocks can be:

* text not separated by an empty line
* inline code
* inline math
* special characters
* latex-like commands
* ...

In the basic case skipping a line will create a paragraph. For instance this sentence is in a different paragraph than the next one.

If you want to introduce a line return without breaking a paragraph, you can use a double backslash `\\` (similar to LaTeX):

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
This allows to easily link on a page (and also across pages).
For instance [this is a link to the Headings section](#headings).

\cmdiff{
  CommonMark supports indicating level 1 and 2 headings by underlying them with `===` or `---`; this is not supported in Franklin.  
}

## Blockquotes

A set of lines prefixed with `>` will form a blockquote as well as continuation lines after those:

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

## (XXX) Priorities

When parsing text and faced with ambiguities, Franklin will stick to the following priority order (whichever matches first is kept):

* raw blocks
*
