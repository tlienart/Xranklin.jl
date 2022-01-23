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

### Index file

The `index.md` file is what Franklin will convert into your website's landing page.
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

In some cases you might want to have full control over the landing page and write it directly in HTML.
In such cases, simply remove the file `index.md` and write a file `index.html` instead.


### Config file

The config file is where you can define global [page variables](/syntax/vars+funs/)
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
which is **crucial** to get your site to [deploy](/workflow/deployment/) properly.

\note{
  The `config.md` file is the only `.md` file in your website folder that won't get converted into a `.html` file by default. Franklin considers it as a special file.
  If you **do** want to have a page with relative URL `/config/`, you can do so by writing a file at `/config/index.md`.
}


### Layout files

The `_layout` folder will usually contain a `head.html` and `foot.html` which are placed respectively at the top and bottom of each generated HTML page (cf. the [page structure](/workflow/getting_started/#page_structure) diagram).

These files are where you should indicate the base layout of your pages and, for instance, where you might indicate what CSS or JS to load on pages.
See [how to adapt a layout](/workflow/adapting_layout/) for more details on how to specify these files if you want to write your own layout.

It is often convenient to split the layout of your site into components and each of these components may have its own layout file to complement the "head" and "foot" files.
For instance you might define a menu in a file `menu.html` and refer to it in the `head.html` using `{{insert menu.html}}`.
To understand how this works in details, you will need to read the section on [page variables and HTML functions](/syntax/vars+funs/)).
For now though, the point is just that there may be more files in `_layout` than just the two basic ones.


## Site and cache folders

When Franklin generates pages, it places them in a `__site` subfolder.
And when the server is interrupted, Franklin generates or updates a `__cache` subfolder.

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

### Site or build folder

The `__site` folder is where all files that correspond to your actual website are placed.
Deploying a Franklin website then simply amounts to placing the content of this `__site` folder on some server (see also [the docs on deployment](/workflow/deployment/) for much more on this).

In the example above, there is a single file in `__site`: the `index.html` which is the landing page of the website.
To fix ideas, let's recall that this file `index.html` is generated out of

* `_layout/head.html`,
* the conversion of `index.md` to HTML by Franklin, and
* `_layout/foot.html`.

If you had other `.md` files
