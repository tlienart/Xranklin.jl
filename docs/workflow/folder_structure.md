<!--
 LAST REVISION: Feb 18, 2022 ✅
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

where `TestWebsite` is the name of the website folder.
In the rest of this page we go over what the different files and folders do.

\tip{
  Paths on this page (and generally, in these docs) are all meant relative to the website folder.
  So for instance if we talk about `foo/bar.md`, it's located at `TestWebsite/foo/bar.md`.
}

### Index file

The root `index.md` file is what Franklin will convert into your website's landing page.
So, for instance, if the content of `index.md` is

```markdown
# Hello

Some text.
```

and that you start the server, the page you will see when navigating to `localhost:8000/`
will contain matching HTML close to:

```html
...
  <h1>Hello</h1>
  <p>Some text.</p>
...
```

In some cases you might want to have full control over the landing page
and write it directly in HTML.
To do so, simply remove the file `index.md` and write a file `index.html` instead.


### Config file

The `config.md` file is where you can define global [page variables](/syntax/vars+funs/)
and [commands](/syntax/extensions/).
As a quick idea of what the `config.md` file can be used to do, this is where you might
specify who the author of the website is, or what the website is about:

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
In short, it is the prefix to use for your site landing page; for instance if your website
is hosted on github, the website might be located at

```
https://username.github.io/theWebsite/
```

and the `base_url_prefix` is then `theWebsite`.

\note{
  The `config.md` file is the only `.md` file in your website folder that won't get
  converted into a `.html` file by default. Franklin considers it as a special file.
  If you **do** want to have a page with relative URL `/config/`, you can do so by
  writing a file at `/config/index.md`.
  See also the section [on paths](#paths_in_franklin).
}


### Layout files

The `_layout/` folder will usually contain a `head.html` and `foot.html` which are placed respectively at the top and bottom of each generated HTML page (cf. the [page structure](/workflow/getting_started/#page_structure) diagram).

These files are where you should indicate the base layout of your pages, and, for instance, where you might indicate what CSS or JS to load on pages.
See [how to adapt a layout](/workflow/adapting_layout/) for more details on how to specify these files if you want to write your own layout.

It is often convenient to split the layout of your site into components, and each of these
components may have its own layout file to complement the "head" and "foot" files.
For instance you might define a menu in a file `menu.html` and refer to it in the `head.html`
using `{{insert menu.html}}`.
To understand how this works in details, you will need to be familiar with the section on
[page variables and HTML functions](/syntax/vars+funs/)).
For now though, the point is just that there may be more files in `_layout/` than just the two basic ones.


## Site and cache folders

When Franklin generates HTML pages, it places them in a `__site/` folder.
And when the server is interrupted, Franklin generates (or updates) a `__cache/` folder.

So after running `serve` and interrupting the server in the basic folder discussed at the previous point, the folder structure would look like

```plaintext
TestWebsite
├── __cache
│   ├── gc.cache
│   └── index
│       └── lc.cache
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
Deploying a Franklin website simply amounts to placing the content of this `__site/` folder
on some server (see also [the docs on deployment](/workflow/deployment/) for much more on this).

In the example above, there is a single file in `__site`: the `index.html` which is the
landing page of the website.
Recall from [the diagram on page structure](/workflow/getting_started/#page_structure)
that this file `index.html` is generated out of assembling and processing

* `_layout/head.html`,
* the conversion of `index.md` to HTML by Franklin, and
* `_layout/foot.html`.

If you had other `.md` files next to `index.md`, these would also be converted and placed in `__site/`.
See also the point below [on paths](#paths_in_franklin) for a summary of where files end up.

### Cache folder

The cache folder keeps track of a serialised representation of the global and each
of the local **contexts**.
At a high level, the global context keeps track of global [page variables](page vars) and the
local contexts keep track of local page variables along with the representation of all code
blocks evaluated on that page.

These serialised representation will only exist under certain (fairly broad) conditions and will
speed up re-building the website on subsequent sessions.
If a context fails to serialise (e.g. because some of the page variables can't be easily serialised),
the context will be re-built every time the server is re-started even if the page hasn't changed
which can lead to a small overhead depending on what's on that page.

If you're curious about the cache, you can read more about it [here](/engine/cache/).
Generally you shouldn't have to think about the cache folder at all.

### Paths in Franklin

The table below helps clarify how a file placed in the website folder ends up
generating a file in the `__site/` folder and, ultimately, the corresponding URL.

For URLs, recall that if we write `/foo/bar/` the browser resolves this as `/foo/bar/index.html` (so the source file is at `/foo/bar/index.html` but users can access the page at `/foo/bar/`).
Also, if the [`base_url_prefix`](/workflow/deployment/#setting_the_base_url_prefix) is `"PREFIX"` then `/foo/bar/` will be `PREFIX/foo/bar/` online (in the table below we assume the prefix is `""`).

For **`.md`** and **`.html`** files:

\lskip


| Source | `__site/` folder | URL |
| -- | -- | -- | -- |
| `index.md` | `index.html`  | `/` |
| `foo.md` (or `foo/index.md`) | `foo/index.html` | `/foo/` |
| `foo/bar.md` | `foo/bar/index.html` | `/foo/bar/` |
| `index.html` | `index.html` | `/` |
| `foo.html`   | `foo/index.html` | `/foo/` |
| `foo/bar.html` | `foo/bar/index.html` | `/foo/bar/` |

\lskip

Observe that there is an ambiguity between a file placed at `foo.md` and `foo/index.md`.
You should pick one of the two based on what makes most sense for your folder structure, but you should not use both simultaneously.

For other files (images etc):

\lskip

| Source | `__site/` folder | URL |
| `a/b.xyz` | `a/b.xyz` | `/a/b.xyz` |
| `_assets/a/b.xyz` | `assets/a/b.xyz` | `/assets/a/b.xyz` |
| `_css/a.css` | `css/a.css` | `/css/a.css` |
| `_libs/a.js` | `libs/a.js` | `/libs/a.js` |

\lskip

**Note**: in some cases you will want some paths to be kept _as is_. This can be done with the global page variable `keep_path`. For instance with things like Google Analytics, you may have to prove ownership of your site by placing a custom HTML file in a given location (see [this tutorial](https://support.google.com/webmasters/answer/9008080#html_verification)).
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

\lskip

| Source | Slug | "`__site/`" folder | URL |
| ------ | ---- | --------- | --- |
| `foo/bar.md` | `slug="biz/baz"` | {`foo/bar/index.html`, `biz/baz/index.html`} | {`/foo/bar/`, `/biz/baz/`} |
| `foo/bar.md` | `slug="biz/baz.html"` | {`foo/bar/index.html`, `biz/baz.html`} | {`/foo/bar/`, `/biz/baz.html`} |

\lskip

## CSS and JS

The files in the `_css/` and `_libs/` folder are copied over to `__site/css/` and
`__site/libs/` respectively.
For instance, let's say that you have

* `_css/layout.css` and,
* `_libs/ui/menu.min.js`

then these files will be copied over (as explained in the [earlier point on paths](#paths_in_franklin)) to

* `__site/css/layout.css` and,
* `__site/libs/ui/menu.min.js`.

You can refer to them in your layout e.g. as:

```html
<link rel="stylesheet" href="/css/layout.css">
<script src="/libs/ui/menu.min.js"></script>
```

\lskip

\tip{
  You should not specify the base url prefix anywhere else than in your `config.md`.
  Franklin will automatically fix paths for you to take it into account.
  In other words you should never have to write `href="/PREFIX/css/layout.css"`,
  stick with `href=/css/layout.css`.
}

## Assets

Everything you put in `_assets/` gets copied _as is_ to `__site/assets` even if
it's a `.md` or `.html` file.
This is the location where you might want to place images, logos, etc.

For instance, we have an image of a bike located at `_assets/eximg/bike.svg`, we can
include it with

\showmd{
  ![Illustration of a road bike](/assets/eximg/bike.svg)
}

This image was taken from Wikimedia Commons [here](https://commons.wikimedia.org/wiki/File:Bike25.svg).

For more on the basic syntax to include images in Franklin, see [here](http://localhost:8000/syntax/basics/#images).
