+++
showtoc = true
header = "Variables and Functions"
+++

## Page variables

### Overview

The main purpose of page variables is to communicate informations
to the layout from the page content though once you get the hang of it, you might use
them for quite a bit more than that.

As a first example, the layout of blog pages might include a small author blurb at the
bottom of the page.
This would be some HTML with slightly different information for each page (e.g.: different
author name, bio, path for mugshot etc.).
For instance the layout could have something like:

```html
<div class="author-card">
  <div class="author-name">{{author_name}}</div>
  <div class="author-blurb">{{author_blurb}}</div>
  <div class="author-mug"><img src="{{author_mug_src}}" alt="{{author_name}}"/></div>
</div>
```

and a given blog post would then define these elements `author-name`, `author-blurb`, and
`author-mug-src` so that they can be inserted:

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

### Defining page variables

Page variables can be defined on any page in a dedicated block fenced with `+++`.
What is placed inside that block must be valid Julia code and will be evaluated
as such, all assignments will be extracted to be made available to Franklin.

There can be multiple such blocks anywhere on a page though, typically, there will
only be one, at the top.
Here's an example where we define two page variables `a` and `b`:

\showmd{
  +++
  a = 5
  b = "hello"
  +++

  Rest of the markdown, we can also expose variables here:
  * `a`: {{a}}
  * `b`: {{b}}
}

Since this is evaluated as Julia code, you can load packages and use code to define
variables:

\showmd{
  +++
  using Dates
  todays_date = Dates.today()
  +++

  Build-date: {{todays_date}}.
}

### Using page variables

Page variables can be used in two ways:

1. inserted in HTML layout or MD content using `{{name_of_variable}}`
2. used inside a HTML-function (_hfun_) using `{{name_of_function name_of_variable}}` (this will be covered in [functions](#functions) below)

The first one is actually a shorthand for `{{fill name_of_variable}}`.
Note that if there is an ambiguity between the name of a variable and the name of a function,
it will be the function that will be called with priority.
There is low risk of this happening but it is up to the user to ensure that variable names
don't clash with function names.

When inserting a page variable with `{{var_name}}` or `{{fill var_name}}`, the Julia function
`string` will be called on the value of `var_name` and that is what will effectively be included.
For basic Julia types, this will typically look like what you would expect but for custom types
that you would have defined or that are defined in a package, you would have to consider what
`string(obj)` returns.

### Getting page variables from specific pages

You can fill the content of a page variable defined on a specific page with
`{{fill var_name relative_path}}` where the `relative_path` indicates the page which
defines `var_name`.

For instance both the current page and `/syntax/basics.md` define a variable `header`, we can get
both:

\showmd{
  * by default we fill from the local page: **{{header}}** (or **{{fill header}}**)
  * but we can query a specific page: **{{fill header syntax/basics}}**
}

the path is relative to the website folder, you can add a `/` at the start and a `.md`
at the end but it's not required.

### Default Local Variables

Franklin defines a number of local page variables with default values that
you can use and overwrite.
Variables with a 🚨 should typically not be set though you may want to use them.

| Variable name | Default value | Purpose / comment |
| ------------- | ------------- | ------- |
| `title` | `nothing` | title of the page |
| 🚨 `hasmath` | `false` | whether the page has math, set automatically |
| 🚨 `hascode` | `false` | whether the page has code, set automatically |
| `date` | `Dates.Date(1)` | publication date of the page |
| `lang` | `"julia"` | default language of executed code blocks |
| `tags` | `String[]` | tags for the page |
| `mintoclevel` | `1` | minimum heading level to add to the table of contents |
| `maxtoclevel` | `6` | maximum heading level to add to the table of contents |
| `showall` | `true` | show the output of each executed code blocks |
| `fn_title` | `"Notes"` | header of the footnotes section |
| 🚨 `_relative_path`  | `""` | relative path to the current page, set automatically (e.g. `/foo/bar.md`) |
| 🚨 `_relative_url`  | `""` | relative url to the current page, set automatically (e.g. `/foo/bar/`) |
| 🚨 `_creation_time`  | `0.0` | timestamp at page creation |
| 🚨 `_modification_time`  | `0.0` | timestamp at last page modification |
| 🚨 `_setvar`  | `Set{Symbol}()` | set of variables assigned on the page |
| 🚨 `_refrefs`  | `LittleDict()` | reference links |
| 🚨 `_eqrefs`  | `LittleDict()` | equation references |
| 🚨 `_bibrefs` | `LittleDict()` | bibliography references |
| 🚨 `_auto_cell_counter`  | `0` | counter for executed code cells for automatic naming |


### (XXX) Not used, need to check

`prerender`, `slug`, `reeval`, `rss*`, `sitemap*`, `robots*`, `latex*`, `fn_title`

## Global variables

Global variables are defined in `config.md` in the same way as (local) page variable and are
available everywhere.
For instance you might define a `author` variable in your `config.md` that would be inserted in
the footer of your layout.

Local page variables take precedence over global page variables so if you define
`author = "ABC"` in `config.md` and `author = "DEF"` in `A.md`, on page `A.md` it is `DEF` that
will be used.

### Default Global Variables

## HTML functions and environments

By now you should already have an idea

* XXX functions can be used in MD no problem
* environments should only be used in HTML (their scope is not resolved in MD which so something like `{{for x in iter}} **{{x}}** {{end}}` will try to resolve `{{x}}` first, fail) (or within a raw HTML block)

### Default functions

### Default environments

\showmd{
  +++
  flag = true
  +++

  {{if flag}}
  Hello
  {{else}}
  Not Hello
  {{end}}
}

\showmd{
  +++
  iter = ["ab", "cd", "ef"]
  +++

  {{for e in iter}}
  _value_ ? **{{e}}**\\
  {{end}}
}

### E-strings

You might want to have conditionals


\showmd{
  {{if e"!($flag)"}}
  Hello
  {{else}}
  Not Hello
  {{end}}
}


### Customising everything

See [here](/syntax/utils/)
