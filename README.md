# Structure


[![CI Actions Status](https://github.com/tlienart/Xranklin.jl/workflows/CI/badge.svg)](https://github.com/tlienart/Xranklin.jl/actions)
[![codecov](https://codecov.io/gh/tlienart/Xranklin.jl/branch/main/graph/badge.svg?token=7gUn1zIEXw)](https://codecov.io/gh/tlienart/Xranklin.jl)

## Ongoing

- there's an issue with lx object, when there's only the lx object, what adds the surrounding `<p></p>`? this is problematic if injecting HTML because it'd be wrapped in a paragraph, same with an ENV block, wtf.

## Goals

* [ ] use FranklinParser.jl
* [ ] remove dependency on HTTP
* [ ] use concrete types and inferrable in-out relations where possible

## Todo

* [ ] need to check whether the CommonMark footnote rule is sufficient, if it is then we should remove the relevant block from FranklinParser as it's not useful.
* [ ] there's a `\par` in latex which needs to be treated same as inline

## Notes

* remind people that in defining latex objects they should be careful with double braces which have a meaning! use whitespace, for instance `\newcommand{\foo}[1]{\bar{#1}}` is not ok, add whitespace around it or skip a line or whatever.
* command names and environment names should be distinct. Cannot have `\newcommand{\foo}{...}` and `\newenvironment{foo}{...}{...}`; only the last one will be picked up.

--

## Conversion

Add ✅ for the ones that are also in one of the test md pages.

* text
  * [x] bold, italic ✅
  * [x] line break ✅
  * [x] horizontal rules
  * [x] comment ✅
  * [ ] header
  * [x] html entities ✅
  * [x] emoji ✅
  * [ ] links
  * [ ] footnotes
  * [ ] images
  * [x] div
  * [x] raw HTML
* md-definition
  * [ ] toml block
  * [ ] `@def`
* lists
  * [ ] unordered
  * [ ] ordered
  * [ ] nested
  * [ ] list item with injection
* tables
  * [ ] basic
  * [ ] cell item with injection
* hfun
  * [ ] double brace injection
  * [ ] function
* code
  * [x] inline
  * [ ] block
  * [ ] block executed
* maths
  * [ ] inline
  * [ ] display
* latex
  * newcommand
    * [x] very basic one ✅
    * [x] test nargs ✅
    * [x] test dedent (e.g. can have an indented def)
    * [-] test problems
  * newenv
    * [x] very basic one
    * [x] test nargs
    * [-] test problems
  * commands
    * [x] basic one with args ✅
    * [x] nesting
    * [ ] basic one with args in maths env
    * [-] test problems
  * environments
    * [ ] basic one with args
    * [ ] nesting
    * [ ] test problems

## Parts from Franklin

### Functions ported

### Files considered

* [ ] include("build.jl") # check if user has Node/minify
* [ ] include("regexes.jl")

* [ ] include("utils/warnings.jl")
* [ ] include("utils/errors.jl")
* [ ] include("utils/paths.jl")
* [ ] include("utils/vars.jl")
* [ ] include("utils/misc.jl")
* [ ] include("utils/html.jl")

* [ ] include("parser/tokens.jl")
* [ ] include("parser/ocblocks.jl")

* [ ] include("parser/markdown/tokens.jl")
* [ ] include("parser/markdown/indent.jl")
* [ ] include("parser/markdown/validate.jl")

* [ ] include("parser/latex/tokens.jl")
* [ ] include("parser/latex/blocks.jl")

* [ ] include("parser/html/tokens.jl")
* [ ] include("parser/html/blocks.jl")

* [ ] include("eval/module.jl")
* [ ] include("eval/run.jl")
* [ ] include("eval/codeblock.jl")
* [ ] include("eval/io.jl")
* [ ] include("eval/literate.jl")

* [ ] include("converter/markdown/blocks.jl")
* [ ] include("converter/markdown/utils.jl")
* [ ] include("converter/markdown/mddefs.jl")
* [ ] include("converter/markdown/tags.jl")
* [ ] include("converter/markdown/md.jl")

* [ ] include("converter/latex/latex.jl")
* [ ] include("converter/latex/objects.jl")
* [ ] include("converter/latex/hyperrefs.jl")
* [ ] include("converter/latex/io.jl")

* [ ] include("converter/html/functions.jl")
* [ ] include("converter/html/html.jl")
* [ ] include("converter/html/blocks.jl")
* [ ] include("converter/html/link_fixer.jl")
* [ ] include("converter/html/prerender.jl")

* [ ] include("manager/rss_generator.jl")
* [ ] include("manager/sitemap_generator.jl")
* [ ] include("manager/robots_generator.jl")
* [ ] include("manager/write_page.jl")
* [ ] include("manager/dir_utils.jl")
* [ ] include("manager/file_utils.jl")
* [ ] include("manager/franklin.jl")
* [ ] include("manager/extras.jl")
* [ ] include("manager/post_processing.jl")
