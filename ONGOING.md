# ONGOING

## Code NB

- Test custom show defined in utils (for mime)
- Test autofig etc
- when using clear, the cache should be removed otherwise it might point to assets that don't exist anymore (e.g figs)

## paths

- output path should be either `site` or `pdf` this should be kwarg
- add a pdf path
- add a cache path
- what is `code_out` / is it useful


## HTML dependent pages

dependencies are ok for markdown pages but if there's a page `foo/bar.html` which has `{{...}}` in it, this becomes tricky because they should also be updated but they get the previous context.

--> there needs to be some thought in terms of what happens when processing a `.html`, whether we construct a simplified LocalContext for that HTML page and then have the `to_trigger` thing or not.
Of course such a page should not have notebooks and vars.


## GOTCHAS

### Caching vars notebook

Only "easily serializable" values (i.e. representable as Julia types Core or Base or Stdlib or composition thereof).
Functions, Modules and any external types will not be & the caching of that page will fail (which is fine).

## Conventions

* `rpath` (`get_rpath`) is always `foo/bar.md` (i.e. includes extension and does not start with `/`)
* `ropath` (`get_ropath`) is always `foo/bar/index.html` and corresponds to a file at `__site/$ropath` or `__pdf/$ropath` or `__cache/$ropath`
* file end with `.html` not `.htm`.
