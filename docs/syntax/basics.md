+++
showtoc = true
header = "Markdown basics"
+++

<!-- avoid having the dummy example headers in the toc -->
{{rm_headers level_1 level_2 level_3 a_text a_text__2}}

## Text

### Emphasis

You can fence a block of text with `*` to change its emphasis (bold, italic):

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

### Special characters

If you want to show the characters `*` or `_` (or other special characters which have a meaning in Franklin), you should escape them with a `\ `:

\showmd{
  \* \_ \$ \` \@ \# \{ \} \~ \! \% \& \'    \\
  \+ \, \- \. \/ \: \; \< \= \> \? \^ \|
}

The double backslash, like in LaTeX, works as a line break (see [next section](#paragraphs)).
Therefore, if you want to show the backslash character, you have to use its HTML entity `&#92;` or `&bsol;`.
You can indeed also insert emojis or HTML-entities:

\showmd{
  ❌ 🐂 🔦 &amp; &pi; &#42; &bsol;
}

## Paragraphs

When converting text (to HTML or LaTeX), sets of consecutive "inline" blocks will be grouped
and placed within a paragraph (in HTML: `<p>...</p>`).
The main inline blocks are:

* a block of text not separated by an empty line possibly including emphasised text and special characters,
* inline code and inline maths,
* latex-like commands.

A paragraph will be interrupted by:

* a line skip (empty line),
* a "non-inline" block (for instance a heading, a code block or a div block),
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

For a unique header text, the anchor will generally be that text, in lowercase, after replacing spaces and special characters by `_`.
So for instance if there's a unique heading `My Heading` the associated anchor will be `#my_heading`.
If there's several heading with the same text, the second heading anchor id will be followed by `__2` and so on.

\showmd{
  ## a text
  ### a text
}

If you hover over the headings above, you'll see that the first one has id `#a_text` and the second one `#a_text__2`.

\cmdiff{
  CommonMark supports indicating level 1 and 2 headings by underlying them
  with `===` or `---` ("_alt heading_") this is not supported in Franklin.  
}

## Blockquotes

A set of lines prefixed with `>` will form a blockquote including continuation lines (i.e. lines immediately after, not separated by an empty line):

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
(unordered list) or a number followed by a dot (`.`) or a bracket (`)`) (ordered list).
Nesting is indicated with either a tab or two or more spaces.

Here's a simple unordered list:

\showmd{
  * Apples
  * Oranges, note that list item can be continued on
  another line, that's fine as long as there's no line-skip
  * Pears
    * Bosc
    * Bartlett
}

Here's a simple ordered list with an unordered nested list
(note that after the first item indicator, the numbering is automatic
and so we can use the same number multiple times):

\showmd{
  1. Apples
  1. Oranges (the indicator for the second item onwards is ignored)
  1. Pears
    + Bosc
    + Bartlett
}

The number of the first item of an ordered list indicates the starting number.
So if you want an ordered list starting from 2 for instance you could do:

\showmd{
  2. Foo
  1) Bar
  1. Baz
}

Note again that the numbering used for the second, third etc items is irrelevant.

List items can contain any "inline" element (e.g. emphasised text or maths):

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
The name of the reference can have spaces in it (and case doesn't matter).
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
  You might want to define link references that can be used on all your pages.
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
  These are not currently supported in Franklin.
}

### Internal links

Every header in Franklin automatically has an anchor attached to it for easy reference.
For instance the current header corresponds to the anchor id `internal_links`.
To link to such an anchor, the same syntax as for links can be used except the path is `#id`, so for instance:

\showmd{
  [internal links](#internal_links)
}

The mapping from anchor name to anchor id does a few things like lowercasing the anchor name, replacing spaces with underscores, dropping special characters etc.
For instance:

* `This Is AN anchor Name` → `this_is_an_anchor_name`
* `anchor α: _foo_` → `anchor_foo`

You can check the generated id by hovering on the header or inspecting the HTML.
Alternatively, you can use global linking (see further below).

You can place anchors anywhere you want with `\label{anchor name}`:

\showmd{
  \label{abcd}

  and now [we refer to it](#abcd)
}

Franklin also allows to link globally **across** pages by using `##` instead of `#`.
So for instance there's a header "_Cache and packages_" defined on the page `/syntax/code/` and you can link to this with

\showmd{
  All three forms link to the same header:

  * [explicit](/syntax/code/#cache_and_packages)
  * [implicit](##cache_and_packages)
  * [implicit 2](## Cache and packages)
}

Observe that in the last case, the mapping `(anchor name) -> (anchor id)` step is implicit.
There's a few additional notes for the global linking:

1. if the anchor is defined on multiple pages, the current page has priority followed by whichever page was seen by Franklin last. This also means that using global linking is ambiguous for anchors that are defined on more than one page (e.g. if you have a section `Introduction` on several pages).
2. further to the previous point, you can use global linking for something defined on the current page, e.g. `[link](## Internal links)`: [link](## Internal links); this isn't ambiguous since the current page has priority.


## Images

Inserting images is very similar to inserting links except there's an additional
exclamation mark to distinguish the two.
The allowed syntax for images are:

* `![](path)` inserts image at `path` without `alt`
* `![alt](path)` inserts image at `path` with `alt`
* `![id]` inserts reference image `id`
* `![alt][id]` inserts reference image `id` with `alt`

The path can be a relative path to the site root or a valid URL to a file.
All images below are taken from Wikimedia Commons.

\showmd{
  ![](/assets/eximg/zebra.svg)
  ![camel](/assets/eximg/camel.svg)
}

For reference images, the syntax is the same as for link references. You can also
add these references in your `config.md` to make them globally available.

\showmd{
  [frog]: https://upload.wikimedia.org/wikipedia/commons/0/08/Creative-Tail-Animal-frog.svg
  [flamingo]: /assets/eximg/flamingo.svg

  ![frog]
  ![a flamingo][flamingo]
}

## Code

To show code, you can use one or two backticks for _inline_ code
and three to five backticks for _block_ code.
Let's see the inline case:

\showmd{
  Inline code: `abc` or ``a`bc``
}

Observe that the code doesn't break the paragraph, also in the second case with double backticks you can
have code with a single backtick without it closing the code environment (this is the main
motivation for ever using two backticks instead of just one).

For blocks (three to five backticks) you can optionally indicate the language of the code
which is useful if you use a library for code highlighting (Franklin templates
use [highlight.js](hljs) by default).

\showmd{
  ```julia
  function foo(x::Int)
    println("hello"^x)
  end
  ```
}

If you want to show a code block within a code block, increase the number of ticks.
For instance in the example below we show a triple-tick code block within a markdown code block
which has 4 ticks.

\showmd{
  ````markdown
  ```julia
  abstract type Foo end
  ```
  ````
}

Franklin supports running Julia code blocks and showing or using the output
of such code blocks. This can be very useful in tutorials for instance.
See [the page on executed code blocks](/syntax/code/) for more on the topic.
Note also that you can even execute Python or R code blocks by leveraging
[PyCall.jl](pycall) or [RCall.jl](rcall).


## Horizontal rules

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
