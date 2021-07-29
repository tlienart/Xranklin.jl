# Notes

## Modules

### Times

Time it takes to generate a new full module:

```
julia> s() = "module Foo_$(abs(rand(Int))) end"
julia> @btime Base.include_string(Main, s())
  700.422 μs (316 allocations: 21.83 KiB)
```

so around `0.7ms`.

Time it takes to re-generate a full module, wiping existing defs:

```
julia> function newmodule(name::String)::Module
    mod = nothing
    mktemp() do _, outf
        redirect_stderr(outf) do
            mod = Base.include_string(Main, """
                module $name end
                """)
        end
    end
    return mod
end
julia> @btime newmodule("abc")
  1.210 ms (329 allocations: 23.60 KiB)
```

This is not a lot but we still don't want to pay that cost once for every page on the full pass.

**Time it takes to call the Module constructor directly (it wipes):**

```
julia> @btime Module(:abc)
  72.420 μs (2 allocations: 672 bytes)
```

yup, that's what we'll use since it's much faster than the other two options and doesn't need to redirect the output even when overwriting.

As a result we:

- (**G**) one global parent module in which all other submodules are evaluated, so that when it's wiped all children modules are inaccessible and should be eventually cleared by GC
- (**G**) have one module for utils (attached to GlobalContext) which gets re-generated every time utils has refreshed definitions
- (**L**) have one module for var defs which gets re-generated every time the page is refreshed
- (**L**) have one module for each page with code, with softscope

## Scopes

During one session we have

### Global Context (one)

* variables (default + what gets defined in `config.md`)
    * one special `:_vars_module  => mod`, a `baremodule` with `softscope`, persistent (fixed name), global markdown definitions get evaluated here
    * one special `:_utils_module => mod`, a `module` with standard scope, non persistent (incrementally-set name, generated every time `utils.jl` is modified)
* definitions (default + what gets defined in `config.md`)

###

* One `LocalContext` per page
  * variables (default + what gets defined in md definitions)
