# Syntax

Note: ✅ is in the integration doc.

## Text

### Basics

* `**bold**`: **bold**
* `_emph_` or `*emph*`: _emph_
* `` `inline code` ``: `inline code`

````
```
block of plaintext code
```
````

```
block of plaintext code
```

### Lists

Unordered:

```
* some item
  * some nested item (note indentation rel to previous)
* some item
```

* some item
  * some nested item (note indentation rel to previous)
* some item

Ordered

```
1. some item
   1. some nested item (note indentation)
1. some item
```

1. some item
   1. some nested item (note indentation)
1. some item

Mixed

```
1. some item
   * some nested item
1. some item
```

1. some item
   * some nested item
1. some item

### Links

* `[basic](https://franklinjl.org)`: [basic](https://franklinjl.org)
* `[anchor](#Links)`: [anchor](#links)
* `[across page](\reflink{link id})`

### Headers

* `# ...`, `## ...` etc
* injects a link unless `:heading_link` (see also `:heading_class`, `:heading_link_class`)

### Raw HTML

## Evaluated Code block

## Maths

### Inline

### Block

## Page variables

**Note**: the `@def ...` is still supported but the `+++...+++` should be preferred to it.


## Hfuns

Evaluated last (and so have access to full page context though maybe not full site context)

## LxFuns

Evaluated during `try_resolve_lxcom` and so only have access to the context up to the calling point.

If a lxcom corresponds to something defined with a newcommand in either the local or global environment, then this is used, with its specific number of args.

If a lxcom corresponds to something defined in Utils or Xranklin (lxfun), then this is used and it will greedily take every braces it can (0 to x) and pass all that as arguments. It's then on the user to have the function check

```
\foo --> calls lx_foo([])
\foo{arg1} --> calls lx_foo([arg1])
\foo{arg1}{arg2} --> calls lx_foo([arg1, arg2])

# careful (though this shouldn't happen...)
\foo{arg1}{arg2}{{arg3}} --> calls lx_foo([arg1, arg2, "{arg3}"])
```
