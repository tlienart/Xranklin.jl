+++
showtoc = true
header = "Using and adapting a layout"
menu_title = "Adapting a layout"
+++

## Overview

Have you seen a great website layout online that you would like to imitate and that is
not already available for Franklin?
This is the page where we explain how you can adapt a layout fairly easily.

Building a great website layout from scratch is difficult, especially if you don't have
a lot of web-dev experience.
We therefore recommend that you either start from one of the
[Franklin-ready templates](https://tlienart.github.io/FranklinTemplates.jl/) or from an
established website template that you found.

## Tips and tricks

### Using page variables

When working on the layout, a key tool will be to leverage [page variables](/syntax/vars+funs/)
so that you can enable specific parts of the layout on specific pages (conditionals) and
extract page information to use in the layout.

For instance, you may have articles in `/posts/...` and would like that all such pages
show a publication date.
You could use a page variable `date` for this with for instance on `/posts/page1.md`:

```md
+++
using Dates
date = Date(2022, 2, 15)
+++

<!-- Here the rest of the page content -->
```

and in your `head.html` you might have something like

```html
...
<head>
  {{ispage posts/*}}
    <title>Post - {{date}}</title>
  {{else}}
    <title>My Website</title>
  {{end}}
</head>
...
```

Of course that's a simplistic example but page variables are very handy to
control the layout of your website.





### Organising layout files

You might find it convenient to define additional layout files in order to separate
(and de-clutter) layout elements.
For instance, let's say your layout includes a menu, you might begin with
a `head.html` looking like

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

As your site grows, this might become more complex, and it then becomes helpful
to have a dedicated file `menu.html` with

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

## Example 1: "Hugo-Coder" template

### Overview

This is an MIT-licensed template designed for Hugo by [Luiz F. A. de Prá](https://github.com/luizdepra).

* Demo site: <https://hugo-coder.netlify.app>,
* Source repo: <https://github.com/luizdepra/hugo-coder> (MIT Licensed).
* [Result site](https://tlienart.github.io/coder-xranklin-demo/) and [repo](https://github.com/tlienart/coder-xranklin-demo).

The way we will go about this is by looking at the source HTML of the demo site and taking the parts we need to rebuild this with Franklin.
Specifically:

* what is the HTML structure (or structures) of pages on that site (the general skeleton of each page),
* what are the _assets_ of the site, things that would potentially be hosted on the server (e.g. stylesheets, icons, ...)
* what are information in the structure that should be controlled by either the `config.md` or pages (e.g. author, publication date, meta tag, ...)

\note{
  This was done in January 2022, the template may have changed a little bit since then but the
  procedure should show you how to adapt or update it easily.
}


### Page structure

When inspecting the HTML of the landing page (and other pages),
the structure is more or less as follows:

```html
...
<head>
  ...
</head>

<body class="preload-transitions colorscheme-auto">
  ...

  <main class="wrapper">
    <nav class="navigation">...</nav>
    <div class="content">...</div>
    <footer class="footer">...</footer>
  </main>
  ...
</body>
</html>
```

This is easy to adapt to Franklin by defining a `_layout/head.html` to contain
everything above `<div class="content">` and `_layout/foot.html` to
contain everything below it.

### Variables

A number of information contained in the page structure can be given or controlled
by [page variables](/syntax/vars+funs/).
For instance:

```html
<meta name="author" content="John Doe">
```

should become

```html
<meta name="author" content="{{author}}">
```

where `author` would typically be defined in `config.md` and possibly be over-written
on a given page.

### Assets

All relative links in the HTML such as

```html
<link rel="icon" type="image/png" href="/images/favicon-32x32.png" sizes="32x32">
```

correspond to assets that you should download, place somewhere appropriate and refer to.
For instance, here, you would download the image (unless, of course, you want another
  favicon), and could place it in `_assets/images/` so that the HTML above becomes

```html
<link rel="icon" type="image/png" href="/assets/images/favicon-32x32.png" sizes="32x32">
```

You would proceed likewise for CSS sheets and JS libraries.
Note that some sites use a [CDN](https://en.wikipedia.org/wiki/Content_delivery_network)
for some of their JS or CSS.
You can always do the same and refer to the same CDN address, or you could download
the file and place it _as is_ in your folder.

I personally _usually_ do the second (host everything) with the following reasoning:

1. it makes it possible to edit the website offline without any difference with how
  the website will look online,
1. it guarantees that what you see is what you get and will stay like this until you change it.

On the other hand, using a CDN (particularly for JS libs) can be good because:

1. it can sometimes help page loading speed (if many websites point to the same address,
  your browser can cache the content),
1. it can make sure the dependence is always up to date (e.g. if you're counting on a JS lib
  where security may be a concern).

\note{
  If you change the path of assets, search your project for places where the asset might be
  referenced to make sure you adjust it everywhere.
  For instance, the template here uses [Fork Awesome](https://forkaweso.me/Fork-Awesome/)
  for the fonts and it refers to it in the CSS via things like `url(../fonts/forkawesome-webfont.eot?v=1.2.0)`,
  and this needs to be adjusted if you placed the fonts somewhere else than in a `/fonts/` folder.
}
