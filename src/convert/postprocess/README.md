# Postprocessing

HTML -> HTML

## Map overview

### HTML2

**Entry**: `html2.jl`

IN: blockified HTML (mostly `{{...}}` blocks)
OUT: ready HTML

Parts that can be processed:

* `:TEXT` (left as is)
* `:SCRIPT` (if `gc[:parse_script_blocks]` then recurse `html2` on the content between the script open and close)
* `:MATH_INLINE`, `:MATH_BLOCK` (left as is, KaTeX or MathJax will handle)
* `:DBB` call `resolve_dbb`

### Resolution of DBB

**Entry**: `dbb.jl` (main fun: `resolve_dbb`)

Early steps

* empty -> nothing
* estring -> `_dbb_fill_estr` which calls `eval_str` (see below)

Steps based on `fname` 

* A - internal HENV (e.g. if)
* A' - orphan HENV (non closed)
* B - hfun (either internal or external)
* C - attempt at fill

#### List of internal stuff

**Entry**: `hfuns/utils.jl`: namely
    * `INTERNAL_HENV_IF` see `hfuns/henv_if.jl`
    * `INTERNAL_HENV_FOR` see `hfuns/henv_for.jl`
    * `INTERNAL_HENV_HFUNS` see `hfuns/{input.jl, tags_pagination.jl, hyperrerfs.jl, dates.jl}`

#### HENV

**Entry**: `hfuns/henv.jl` with main function `find_henv`

#### HFUN (internal/external)

**Entry**: `dbb.jl` with function `_dbb_fun` which relies on `outputof`
**Second**: `convert/outputof.jl` with function `outputof`

#### FILL

**Entry**: `dbb.jl` with function `_dbb_fill` 


### Eval str

**Entry**: `hfuns/evalstr.jl` function `eval_str`
