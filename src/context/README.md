# Context

## Map overview

### Context

**Entry**: `context.jl`

* `GlobalContext <: Context`
* `LocalContext <: Context`

#### Notebook

**Entry**: `notebook.jl` then `code/*.jl`

* `VarsNotebook <: Notebook`
* `CodeNotebook <: Notebook`


#### Utils

* `default_context.jl`
* `context_utils.jl` (operations on `Context` objects)
* `deps_map.jl` (attached to GC to keep track of what page depends on what)
* `serialize.jl` (serialize context objects)


### Other general things

#### Anchors and Tags

**Entry**: `anchors.jl`, `tags.jl`

#### RSS

**Entry**: `rss.jl`

### Misc

**Entry**: `types.jl`
