# ONGOING

## Code NB

- Test custom show defined in utils (for mime)
- Test autofig etc
- when using clear, the cache should be removed otherwise it might point to assets that don't exist anymore (e.g figs)

## GOTCHAS

### Caching vars notebook

Only "easily serializable" values (i.e. representable as Julia types Core or Base or Stdlib or composition thereof).
Functions, Modules and any external types will not be & the caching of that page will fail (which is fine).
