# ONGOING

## Sept 10

* `_list` should be there (table as well), this means also adding validation.

## Code NB

- Test custom show defined in utils (for mime)
- Test autofig etc
- when using clear, the cache should be removed otherwise it might point to assets that don't exist anymore (e.g figs)

- add possibility to specify a location for the page's Project.toml activate an env when evaluating code in `nb_code`; maybe think a bit more about where user would put stuff etc; these would need to be folders and it would need to not be too painful, maybe can make this automatic so that when working on a page they can activate stuff and it goes directly somewhere?

## paths

- output path should be either `site` or `pdf` this should be kwarg
- add a pdf path
- add a cache path
- what is `code_out` / is it useful

## weird

- make lxdefs Symbol => LxDef otherwise there's an incoherence with pagevars also at hfun/lxfun level so annoying.


## HTML dependent pages

dependencies are ok for markdown pages but if there's a page `foo/bar.html` which has `{{...}}` in it, this becomes tricky because they should also be updated but they get the previous context.

--> there needs to be some thought in terms of what happens when processing a `.html`, whether we construct a simplified LocalContext for that HTML page and then have the `to_trigger` thing or not.
Of course such a page should not have notebooks and vars.

Test this (as well as dependencies in general)

* gc modif --> page.md updated
* page modif --> page2.md updated
* gc modif --> page.html updated
* page modif --> page.html updated

## GOTCHAS

### Caching vars notebook

Only "easily serializable" values (i.e. representable as Julia types Core or Base or Stdlib or composition thereof).
Functions, Modules and any external types will not be & the caching of that page will fail (which is fine).

## Conventions

* `rpath` (`get_rpath`) is always `foo/bar.md` (i.e. includes extension and does not start with `/`)
* `ropath` (`get_ropath`) is always `foo/bar/index.html` and corresponds to a file at `__site/$ropath` or `__pdf/$ropath` or `__cache/$ropath`
* file end with `.html` not `.htm`.
