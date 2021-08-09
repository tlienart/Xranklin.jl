# ONGOING

## Code NB

- Test custom show defined in utils
- Test autofig
- add serialization using JSON3 (Notebook -> Json and load from Json)

Note: when using `clear` the cache should be removed as well otherwise it might point to assets that don't exist anymore. Otherwise we assume that the assets are not removed by the user (...).


- also need to serialize vars notebook so that we know which var has been assigned in the notebook, this is useful in disambiguiating between a var available at both local and global level where we need to figure out which one to use

- test that if a value is given globally then it overrides the default local vars; need to think a bit about how to this cleanly, whether to drop bindings if they're defined globally or something... use case is if a user wants to specify another default for a local page var.
It might be possible to figure out which was given 'first' (or takes priority) based on whether the variable is one of the assignments...

==> test this global/local clash thing


## GOTCHAS

### Variable assignments

- var is defined in glob
- var is defined in loc with `setvar!` and so doesn't appear in assignments
- in that case the glob *will* be used as Xranklin won't know that the local value should be favoured.  so users should basically not do that

**Rem**: if this somehow becomes an issue, we could save the assignments done by `setvar!`... but this seems a bit overkill for now.
