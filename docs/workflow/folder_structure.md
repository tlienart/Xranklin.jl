<!--
 LAST REVISION: Jan 28, 2022  (XXX incomplete)
 -->

+++
showtoc = true
header = "Folder Structure"
menu_title = header
+++


## Basic folder structure

A Franklin-compatible website folder will always have the following basic structure:

```plaintext
TestWebsite
├── _layout
│   ├── foot.html
│   └── head.html
├── config.md
└── index.md       # or index.html
```

where `TestWebsite` is the title of the website folder.
Let's go over what these different files do.

Paths on this page are all meant relative to the website folder so for instance if
we talk about `foo/bar.md` it's located at `TestWebsite/foo/bar.md`.

### Index file

The root `index.md` file is what Franklin will convert into your website's landing page.
So, for instance, if the content of `index.md` is

```markdown
# Hello

Some text.
```

and that you start the server, the page you will see when navigating to `localhost:8000/`
will contain matching HTML like:

```html
...
  <h1>Hello</h1>
  <p>Some text.</p>
...
```

In some cases you might want to have full control over the landing page
and write it directly in HTML.
In such cases, simply remove the file `index.md` and write a file
`index.html` instead.


### Config file

The `config.md` file is where you can define global [page variables](/syntax/vars+funs/)
and [commands](/syntax/extensions/).
As a quick idea of what the `config.md` file can be used to do, this is where you might
specify who the author of the website is, or what it's about:

```plaintext
+++
author = "Zenobia"
descr = """
  This website is dedicated to Zenobia, a famous queen of Syria.
  """
+++
```

It is also the place where you will define the `base_url_prefix` (or `prepath`)
which is **crucial** to get your site to [deploy properly](/workflow/deployment/).

\note{
  The `config.md` file is the only `.md` file in your website folder that won't get
  converted into a `.html` file by default. Franklin considers it as a special file.
  If you **do** want to have a page with relative URL `/config/`, you can do so by
  writing a file at `/config/index.md`.
}


### Layout files

The `_layout/` folder will usually contain a `head.html` and `foot.html` which are placed respectively at the top and bottom of each generated HTML page (cf. the [page structure](/workflow/getting_started/#page_structure) diagram).

These files are where you should indicate the base layout of your pages and, for instance, where you might indicate what CSS or JS to load on pages.
See [how to adapt a layout](/workflow/adapting_layout/) for more details on how to specify these files if you want to write your own layout.

It is often convenient to split the layout of your site into components and each of these components may have its own layout file to complement the "head" and "foot" files.
For instance you might define a menu in a file `menu.html` and refer to it in the `head.html` using `{{insert menu.html}}`.
To understand how this works in details, you will need to read the section on [page variables and HTML functions](/syntax/vars+funs/)).
For now though, the point is just that there may be more files in `_layout/` than just the two basic ones.


## Site and cache folders

When Franklin generates HTML pages, it places them in a `__site/` folder.
And when the server is interrupted, Franklin generates (or updates) a `__cache/` folder.

So after running `serve` and interrupting the server in the basic folder discussed at the previous point, the folder structure would look like

```plaintext
TestWebsite
├── __cache
│   ├── gnbv.cache
│   └── index
│       └── pg.hash
├── __site
│   └── index.html
├── _layout
│   ├── foot.html
│   └── head.html
├── config.md
└── index.md
```

These two folders are explained below along with a summary of how paths work in Franklin.

### Site folder

The `__site/` folder is where all files that correspond to your actual website are placed.
Deploying a Franklin website simply amounts to placing the content of this `__site/` folder on some server (see also [the docs on deployment](/workflow/deployment/) for much more on this).

In the example above, there is a single file in `__site`: the `index.html` which is the landing page of the website.
Recall that this file `index.html` is generated out of assembling and processing

* `_layout/head.html`,
* the conversion of `index.md` to HTML by Franklin, and
* `_layout/foot.html`.

If you had other `.md` files next to `index.md`, these would also be converted and placed in `__site/`.
See also the point below [on paths](#paths_in_franklin) for a summary of where files end up.

### Cache folder

The cache folder keeps track of a number of elements that may help speed up re-building your website.
At a high-level the cache folder tries to:

- keep track of a hash of each page to see if they've changed since the last time they were built to reduce the need of having to re-build pages,
- keep track of all page variables defined on each page to avoid having to re-evaluate them,
- keep track of the output of all code blocks to try to avoid having to re-execute them.

The use of the word _try_ is important here, there are many cases where the cache will be ignored.
Generally though, you shouldn't have to think about the `__cache/` folder.
If you're curious, you can read more about it [here](/engine/cache/).

A single page `foo.md` can generate between one and three cache files (see the next point for their location)

* a `pg.hash` which contains a hash of the page `foo.md`,
* a `nbv.cache` which contains a serialised version of the [page variables][page vars] defined on the page,
* a `nbc.cache` which contains the string representation of [evaluated code blocks][code eval] and the string representation of their results.

### Paths in Franklin

The table below helps understanding how a file placed in the website folder is connected
to files in `__site/` and `__cache/`.
The files between brackets are optionally generated depending on the context.
For URLs, recall that if we write `/foo/bar/` the browser resolves this as `/foo/bar/index.html` (so the source file is at `/foo/bar/index.html` but users can access the page at `/foo/bar/`).

\lskip


| Source | `__site/` folder | URL |
| -- | -- | -- | -- |
| `index.md` | `index.html`  | `/` |
| `foo.md` (or `foo/index.md`) | `foo/index.html` | `/foo/` |
| `foo/bar.md` | `foo/bar/index.html` | `/foo/bar/` |
| `index.html` | `index.html` | `/` |
| `foo.html`   | `foo/index.html` | `/foo/` |
| `foo/bar.html` | `foo/bar/index.html` | `/foo/bar/` |
| `a/b.xyz` | `a/b.xyz` | `/a/b.xyz` |
| `_assets/a/b.xyz` | `assets/a/b.xyz` | `/assets/a/b.xyz` |
| `_css/a.css` | `css/a.css` | `/css/a.css` |
| `_libs/a.js` | `libs/a.js` | `/libs/a.js` |

\lskip

Observe that there is an ambiguity between a file placed at `foo.md` and `foo/index.md`.
You should pick one of the two based on what makes most sense for your folder structure, but you should not use both simultaneously.

**Note**: in some cases you will want some paths to be maintained. This can be done with the global page variable `keep_path`. For instance with things like Google Analytics, you may have to prove ownership of your site by placing a custom HTML file in a given location (see [this tutorial](https://support.google.com/webmasters/answer/9008080#html_verification)).
For such cases you would indicate `keep_path=["the/path.html"]` and Franklin would respect that:

```plaintext
# source
the/path.html

# in config.md
keep_path = ["the/path.html"]

# output in __site/
the/path.html    # (instead of the/path/index.html)
```

Further to the global page variable `keep_path`, you can also use the page variable `slug` which
offers you a way to indicate a secondary output path for a file thereby making it available at
another URL. The table below should clarify this:

| Source | Slug | "`__site/`" folder | URL |
| ------ | ---- | --------- | --- |
| `foo/bar.md` | `slug="biz/baz"` | {`foo/bar/index.html`, `biz/baz/index.html`} | {`/foo/bar/`, `/biz/baz/`} |
| `foo/bar.md` | `slug="biz/baz.html"` | {`foo/bar/index.html`, `biz/baz.html`} | {`/foo/bar/`, `/biz/baz.html`} |

\lskip

To close off this point about paths, here's a short summary of how source files can generate cache files, you should generally not have to worry about this but might be curious:

\lskip

| Source | "`__cache/`" folder |
| -- | -- |
| `index.md` | `index/pg.hash`, (`index/nbc.cache`, `index/nbv.cache`) |
| `foo.md` | `foo/pg.hash` (`foo/nbc.cache`, `foo/nbv.cache`) |
| `foo/bar.md` | `foo/bar/pg.hash`, (`foo/bar/nbc.cache`, `foo/bar/nbv.cache`) |

\lskip

If you're interested about what the cache does and how it works, check out [this section](/engine/cache/).

## Other pages

## CSS and JS

## Assets

## Literate
