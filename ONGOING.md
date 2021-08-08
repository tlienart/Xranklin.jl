# ONGOING

## Code NB

- Test custom show defined in utils
- Test autofig
- add serialization using JSON3 (Notebook -> Json and load from Json)

Note: when using `clear` the cache should be removed as well otherwise it might point to assets that don't exist anymore. Otherwise we assume that the assets are not removed by the user (...).


- test that if a value is given globally then it overrides the default local vars; need to think a bit about how to this cleanly, whether to drop bindings if they're defined globally or something... use case is if a user wants to specify another default for a local page var
