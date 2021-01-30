# Structure

## Goals

* [ ] use FranklinParser.jl
* [ ] remove dependency on HTTP
* [ ] use concrete types and inferrable in-out relations where possible

## Todo

* [ ] need to check whether the CommonMark footnote rule is sufficient, if it is then we should remove the relevant block from FranklinParser as it's not useful.

--


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
