# ONGOING

## Code NB

- Test custom show defined in utils (for mime)
- Test autofig etc
- add serialization using JSON3 (Notebook -> Json and load from Json)

Note: when using `clear` the cache should be removed as well otherwise it might point to assets that don't exist anymore. Otherwise we assume that the assets are not removed by the user (...).

- Test stale notebook stuff

## GOTCHAS

### Caching vars notebook

Would require being able to serialize any value that could go into a page var. In theory this can be done via the Julia serializer or whatever but let's say a user does something like this:

```
+++
using OrderedCollections
d = LittleDict(:a=>5, :b=>7)
+++
```

then the serialization should indicate that the module `OrderedCollections` is required.

One approach *could* be to use JLD (or JLD2) for this (also to keep the result of evaluation of code cells). For now this is not done as it's a significant project in its own right.
