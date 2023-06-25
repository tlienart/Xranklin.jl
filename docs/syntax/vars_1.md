+++
showtoc = true
header = "Page Variables (part 1)"
menu_title = header
+++

## Overview

The main purpose of page variables is to communicate informations
to the HTML layout from the page content.
However, once you get the hang of it, you might decide to use them for quite
a bit more than that.

As a first example, let's say that you would like the layout of your blog pages to
include an author blurb at the bottom.
This could be some fixed HTML structure with different information for each page (e.g.: different
author name, bio, path for mugshot, ...).

In Franklin you can indicate this in the layout with something like:

```html
<div class="author-card">
  <div class="author-name">{{author_name}}</div>
  <div class="author-blurb">{{author_blurb}}</div>
  <div class="author-mug">
    <img src="{{author_mug_src}}" alt="{{author_name}}"/>
  </div>
</div>
```

The `{{author_name}}` syntax means "_insert the content of the `author_name` page variable here_".
Page variables can be defined in the Markdown of a page inside a block fenced with '`+++`':

```plaintext
+++
author_name  = "Emmy Noether"
author_blurb = """
  German mathematician who made many important
  contributions to abstract algebra.
  """
author_mug = "/assets/emmy.png"
+++
```

This might already give you a good idea but let's dive into the specifics.

## Page variables basics

### Assignment

Page variables can be defined on any page in a dedicated block fenced with '`+++`'.
We'll call such a block a _def-block_ from now on.
What is placed inside that block must be valid Julia code and will be evaluated
as such, all assignments will be extracted.

There can be multiple such blocks anywhere on a page though, typically, there will
only be one, at the top.
Here's an example where we define two page variables `a` and `b`, page variables can be
accessed from within the Markdown itself or in the HTML layout:

\showmd{
  +++
  a = 5
  b = "hello"
  +++

  Rest of the markdown, we can also expose variables here:
  * `a`: {{a}}
  * `b`: {{b}}
}

Since the content of the def-block is evaluated as Julia code, you can load packages
and use code to define variables:

\showmd{
  +++
  using Dates
  todays_date = Dates.today()
  +++

  Build-date: {{todays_date}}.
}
\lskip

### Usage

Page variables can be used with the following syntax:

```
{{name_of_function name_of_var_1 ...}}
```

The case `{{name_of_var}}` is a shortcut for `{{fill name_of_var}}`.
Note that if there is a clash between the name of a var and the name of a function, the function
will be called with priority.

The functions called in such a way are called HTML-functions or _hfuns_ for short and can have
zero or more arguments.
There are several core functions like `fill` and you can define your own as we will show
[further](#hfuns).

When inserting a page variable with `{{var_name}}` or `{{fill var_name}}`, the Julia function
`repr` will be called on the value of `var_name` and that is what will effectively be included.
For basic Julia types (`Int`, `Bool`, ...), this will typically look like what you
would expect but for custom types that you would have defined or that are defined in a package,
you would have to consider what `repr(obj)` returns.
For types in `AbstractString`, `repr(obj)` adds quotation marks which are stripped.

\showmd{
  +++
  a = true
  b = [1,2,3]
  c = Dict(:a => 5, :b => 7)
  +++

  * a: {{a}}
  * b: {{b}}
  * c: {{c}}
}
\lskip

### Local and global contexts

In a Franklin session there is a _global_ (site-wide) context and a set of _local_ (page-related)
contexts which are attached to it.
Page variables can be assigned at both levels.
You have already seen how to do so at a page-level by just adding a `+++...+++` block in
the corresponding Markdown, you can do the same at global-level by adding such a block
in your `config.md` file.

Variables defined at global-level are accessible from anywhere whereas variables defined
at local-level are only directly accessible from the page on which they are defined (see
also the [next point](##cross page vars)).
When a variable is defined at both levels, the local one takes precedence.


\label{cross page vars}
### Accessing variables defined on another page

You can fill the content of a page variable defined on another page with

```
{{fill var_name relative_path}}
```

where the `relative_path` indicates the relative path to the page which
defines `var_name`.

For instance both the current page and `/syntax/basics.md` define a variable `header`:

\showmd{
  * by default we fill from the local page: **{{header}}** (or **{{fill header}}**)
  * but we can query a specific page: **{{fill header syntax/basics}}**
}

The path is relative to the website folder.
You can add a `/` at the start and a `.md` at the end but it's not required.

### Updating page variables

When a local or global page variable is updated, any page that refers to it will be re-built so that the full website takes the new definition into account.

To help keep this process simple and fast, there are two constraints in how you can use page variables:

1. do not have references of depth more than 1 (i.e. a page variable can be defined by a reference to another page variable but no more depth than that)
2. avoid using page variables in executed code blocks.


## Default variables

Franklin defines a number of page variables with default values that
you can use and overwrite.
You don't have to use or set any of those unless you find one useful.

### Local variables

\lskip

| Variable name | Default value | Purpose / comment |
| ------------- | ------------- | ------- |
| `title` | `nothing` | title of the page |
| `date` | `Dates.Date(1)` | publication date of the page |
| `lang` | `"julia"` | default language of executed code blocks |
| `tags` | `String[]` | tags for the page (see [tags](/extras/tags/)) |
| `slug` | `""` | slug for the page (see below) |
| `ignore_cache` | `Bool` | if `true` re-evaluate all the code on the page on first pass |
| `mintoclevel` | `1` | minimum heading level to add to the table of contents |
| `maxtoclevel` | `6` | maximum heading level to add to the table of contents |
| `showall` | `true` | show the output of every executed code blocks |
| `fn_title` | `"Notes"` | heading of the footnotes section |

\lskip

The `slug` variable allows you to specify an explicit secondary output location
for the page.
For instance if you're currently working on a page `a/b/c.md`, the default output
path will be such that the relevant page can be addressed at `/a/b/c/`.
However if you specify `slug = "c/d"` then that page will also be available at `/c/d/`.
You can also specify a path with a `.html` extension in which case exactly that path
will be used:

* `slug = "c/d"` → the page will also be available at `/c/d/`
* `slug = "c/d.html"` → the page will also be available at `/c/d.html`

For more on the topic you might want to read about [default paths in Franklin](##Paths in Franklin).
Check also the `keep_path` global variable in the [next section](#global_variables).

<!-- \\
There's also a number of "internal" page variables that are set and used by Franklin,
you might sometimes find those useful to build more advanced functionalities but
you should typically not set them yourself unless you're sure of what you're doing.

| Variable name | Default value | Purpose / comment |
| ------------- | ------------- | ------- |
| `_hasmath`  | `false` | whether the page has math |
| `_hascode`  | `false` | whether the page has code |
| `_relative_path` | `""` | relative path to the current page (e.g. `/foo/bar.md`) |
| `_relative_url`  | `""` | relative url to the current page (e.g. `/foo/bar/`) |
| `_creation_time` | `0.0` | timestamp at page creation |
| `_modification_time`  | `0.0` | timestamp at last page modification |
| `_setvar`        | `Set{Symbol}()` | set of variables assigned on the page |
| `_anchors`       | `Set{String}()` | set of anchor ids defined on the page |
| `_refrefs`       | `LittleDict()`  | reference links defined on the page |
| `_eqrefs`        | `LittleDict()`  | equation references |
| `_bibrefs`       | `LittleDict()`  | bibliography references |
| `_auto_cell_counter`  | `0` | counter for executed code cells for automatic naming |

\\
For legacy purposes, a number of these variables have aliases (which can be used):

| Alias | Variable name |
| ----- | ------------- |
| `fd_rpath` | `_relative_path` |
| `fd_url` | `_relative_url` |
| `fd_ctime` | `_creation_time` |
| `fd_mtime` | `_modification_time` |
| `reeval` | `ignore_cache` |
| `hasmath` | `_hasmath` |
| `hascode` | `_hascode` | -->



### Global variables

Just as with default local variables, you might find it useful to access or set some of those though many
might be irrelevant for you.


| Variable name | Default value | Purpose / comment |
| ------------- | ------------- | ------- |
| `author`  | `The Author` |  |
| `base_url_prefix` | `""` | the site's base URL prefix (see also [how to deploy](## howto prepath)) |
| `website_url`   | `""` | |
| `content_tag`    | `"div"` | the HTML tag which will wrap the content (can be empty) |
| `content_class`  | `"franklin-content"` | the class of the content wrapper |
| `content_id`     | `""`    | the id of the content wrapper |
| `autosavefigs` | `true`  | whether to automatically save figures |
| `autoshowfigs` | `true`  | whether to automatically show figures |
| `layout_head`  | `"_layout/head.html"` | the path to the layout head file (see also [page structure](/workflow/page_structure/)) |
| `layout_foot`  | `"_layout/foot.html"` | the path to the layout foot file |
| `layout_page_foot` | `"_layout/page_foot.html"` | the path to the page foot file |
| `layout_head_lx` | `"_layout/latex/head.tex"` | the path to the LaTeX preamble |
| `parse_script_blocks` | `true` | whether to parse `<script>` blocks |
| `date_format` | `"U d, yyyy"` | base date format used |
| `date_days`   | `String[]`    | specify custom day names (e.g. `["Lundi", ...]`) |
| `date_shortdays` | `String[]` | specify custom short day names (e.g. `["Lun", ...]`) |
| `date_months` | `String[]` | specify custom month names (e.g. `["Janvier", ...]`) |
| `date_shortmonths` | `String[]` | specify custom short month names (e.g. `["Jan", ...]`) |
| `ignore_base` | `["LICENSE.md", "README.md", ...]` | base list of strings or regexes of files and directories to ignore |
| `ignore` | `[]` | complements `ignore_base` |
| `keep_path` | `String[]` | relative paths of files that should have their build path be identical to their source path |
| `robots_disallow` | `String[]` | relative paths of files that should disallow robots |
| `generate_robots` | `true` | whether to generate `robots.txt` |
| `generate_sitemap` | `true` | whether to generate a sitemap |
| `heading_class` | `""` | class to add to headings (converted from `## ...`) |
| `heading_link`  | `true` | whether to make headings into links |
| `heading_link_class` | `""` | class of the heading links if any |
| `heading_post` | `""` | HTML that should be placed after every heading if any (can contain `{{...}}`) |
| `toc_class` | `"toc"` | class of the table of contents |
| `anchor_class` | `"anchor"` | class of the page anchors |
| `anchor_math_class` | `"anchor-math"` | class of anchors in math environment |
| `anchor_bib_class`  | `"anchor-bib"` | class of anchors in references |
| `date_format` | `"U dd, yyyy"` | date format on the site |
| `date_days` | `String[]` | |
| `date_shortdays` | `String[]` | |
| `date_months` | `String[]` | |
| `date_shortmonths` | `String[]` | |
| `generate_rss` | `false` | whether to generate an RSS feed |
| `rss_website_title` | `""` | |
| `rss_feed_url`      | `""` | |
| `rss_website_descr` | `""` | |
| `rss_file`          | `"feed"` | file name for the RSS feed |
| `rss_full_content`  | false | whether to insert the full page content on RSS items |
| `tags_prefix`  | `"tags"` | tags will be at `/tags/...`|
| `tabs_tospaces`  | `2` | conversion tabs to spaces in list creation |


Same as for local variables, there is a set of default global variables that are used by Franklin and
which you should, generally, not set yourself though you might want to access them.

| Variable name | Default value | Purpose / comment |
| ------------- | ------------- | ------- |
| `_offset_lxdefs` |  |  |
| `_paths` |  |  |
| `_idx_rpath` |  |  |
| `_idx_ropath` |  |  |
|`_utils_hfun_names` |  |  |
|`_utils_lxfun_names` |  |  |
|`_utils_envfun_names` |  |  |
|`_utils_var_names` |  |  |
|`_refrefs` |  |  |
|`_bibrefs` |  |  |

\\
For legacy purposes, a number of these variables have aliases:

| Alias | Variable name |
| ----- | ------------- |
| `prepath` | `base_url_prefix` |
| `prefix` | `base_url_prefix` |
| `base_path` | `base_url_prefix` |
| `website_url` | `rss_website_url` |
| `website_title` | `rss_website_title` |
| `website_description` | `rss_website_descr` |
| `website_descr` | `rss_website_descr` |


