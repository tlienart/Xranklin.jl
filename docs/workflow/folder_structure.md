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


### Layout files

The `_layout` folder will usually contain a `head.html` and `foot.html` which are appended at the top and bottom of the HTML coming from the Markdown conversion (cf. the [page structure](/workflow/getting_started/#page_structure) diagram).

These files are where you should indicate the base layout of your pages and, for instance, where you might indicate what CSS or JS to load on pages.
See [how to adapt a layout](/workflow/adapting_layout/) for more details on how to specify these files if you want to write your own layout.

You might find it convenient to define additional layout files in order to separate (and de-clutter) layout elements.
For instance, let's say your layout includes a menu, you might begin with a `head.html` looking like

```html
<html>
<head>
  <title> The title </title>
</head>

<nav>
  <ul>
    <li><a href="/home/">Home</a></li>
    <li><a href="/posts/">Posts</a></li>
    <li><a href="/about/">About</a></li>
  </ul>
</nav>

<body>
```

As your site grows, this might become more complex and it then becomes helpful to a file `menu.html` with

```html
<nav>
  <ul>
    <li><a href="/home/">Home</a></li>
    <li><a href="/posts/">Posts</a></li>
    <li><a href="/about/">About</a></li>
  </ul>
</nav>
```

and indicate that this file should be _inserted_ in the `head.html`:

```html
<html>
<head>
  <title> The title </title>
</head>

{{insert menu.html}}

<body>
```

This allows to split your layout in smaller bits that are easier to maintain.
The `{{...}}` syntax indicates we're calling the ["HTML" function](/syntax/vars+funs/) `insert`.
For that function, paths are taken relative to the `_layout` folder (so here `menu.html` is assumed to be next to `head.html`).

## Site and cache folders
