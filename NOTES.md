# Notes

## Modules

### Module creation + eval

The fastest way to create a module as a namespace is to use the constructor:

```
julia> @btime Module(:abc)
  72.420 μs (2 allocations: 672 bytes)
```

evaluation inside such a module via `include_string(m, code)` or `include_string(softscope, m, code)` incurs an overhead especially if the code defines functions:

```
julia> m = Module(:abc); @btime include_string($m, "a=5")
  91.039 μs (48 allocations: 2.81 KiB)
julia> m = Module(:abc); @btime include_string($m, "a = 5; foo() = 0.5")
  320.534 μs (178 allocations: 11.49 KiB)
```

### What we do

- (**G**) one global parent module in which all other submodules are evaluated, so that when it's wiped all children modules are inaccessible and should be eventually cleared by GC
- (**G**) one module for utils which gets re-generated every time utils has refreshed definitions
- (**G**) one module for vars which gets wiped every time we switch context and within a page uses softscope
- (**L**) have one module for each page with code, with softscope

## Possible time optimisations

* keep track of the hashes of mddefs seen within the life of `vars_module`, if it's in the list, skip
