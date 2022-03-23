+++
showtoc = true
header = "Using tags and pagination"
menu_title = "Tags & pagination"

item_list = [
  "* item $i\n"
  for i in 1:10
]
+++

## Tags

### Overview

You can add tags to a page by filling the `tags` page variable.
For instance

```plaintext
+++
...
tags = ["foo", "a tag", "another tag"]
...
+++
```

Franklin will automatically generate tag pages where it gathers all pages that have a specific
tag.
Following the example above, there will be a page `/tags/foo/index.html` with a list of links
to pages that have the `"foo"` tag.

If you add or remove tags, Franklin will take care of updating these pages, possibly deleting them if necessary.

### Specifying how tag pages look like

By default, tag pages are generated with a structure like

```html
...
<head>
  ...
  <title>Tag: {{fill tag_name}}</title>
</head>
<body>
  <div class="tagpage">
    {{taglist}}
  </div>
</body>
...
```

where `taglist` is an internal [hfun] generating a simple list with items:

```html
<li>
  <a href="..url-to-page..">..page-title..</a>
</li>
```

You can alter both of these things by providing a `_layout/tag.html` (which will then be used
to generate the tag pages), or re-defining a `hfun_taglist` (or both).

## Pagination

Say that, for a blog, you have a list of 100 pages but you would like to show
it 10 pages at the time.
This is an example where _pagination_ helps.

Basically, you indicate a list over which to paginate, the number of items to place per
page, and Franklin will generate this page with each chunk of items.

Let's see an example first:

{{paginate item_list 5}}

the `item_list` is defined as

```julia
item_list = [
  "* item $i\n"
  for i in 1:10
]
```

on the current page, only the first five items of the list are shown; on [the next one](/extras/tags/2/)
you'll see that it's the exact same page except with the other 5 items.
