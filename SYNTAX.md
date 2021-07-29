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
* injects a link unless `:header_link` (see also `:header_class`, `:header_link_class`)

### Raw HTML

## Evaluated Code block

## Maths

### Inline

### Block
