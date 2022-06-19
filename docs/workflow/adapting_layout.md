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

Of course that's a simplistic example, but it should hopefully demonstrate that
page variables can be very handy to control the layout of your website.





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

## Example 1: "Minima-Reboot" template

### Overview

This is an MIT-licensed template which is a Bootstrap port of Jekyll's default theme, designed by [Alexander Terenin](https://github.com/aterenin/minima-reboot/).

* Demo site: <https://aterenin.github.io/minima-reboot/>,
* Source repo: <https://github.com/aterenin/minima-reboot> (MIT Licensed),
* [Result site](https://tlienart.github.io/coder-minima-reboot-demo/) and [repo](https://github.com/tlienart/minima-reboot-xranklin-demo).

The way we will go about this is by looking at the source HTML of the demo site and taking the parts we need to rebuild this with Franklin.
Specifically:

1. what is the HTML structure (or structures) of pages on that site (the general skeleton of each page),
1. what are the _assets_ of the site, things that would potentially be hosted on the server (e.g. stylesheets, icons, ...)
1. what are information in the structure that should be controlled by either the `config.md` or pages (e.g. author, publication date, meta tag, ...)

\note{
  This was done in January 2022, the template may have changed a little bit since then but the
  procedure should show you how to adapt or update it easily.
}

### Page structure

When inspecting the HTML f the landing page (and other pages), the structure is more or less
as follows:

```html
```


## Example 2: "Hugo-Coder" template

### Overview

This is an MIT-licensed template designed for Hugo by [Luiz F. A. de Prá](https://github.com/luizdepra).

* Demo site: <https://hugo-coder.netlify.app>,
* Source repo: <https://github.com/luizdepra/hugo-coder> (MIT Licensed),
* [Result site](https://tlienart.github.io/coder-xranklin-demo/) and [repo](https://github.com/tlienart/coder-xranklin-demo).

We will proceed as with the Minima Reboot example.


### Page structure

When inspecting the HTML of the landing page (and other pages) (after un-minification using
something like [unminify2](https://www.unminify2.com/)), we can observe that the structure
is more or less as follows:

```html
...
<head>
  ...
</head>

<body>
  <header ...>
  </header>

  <main ...>
  </main>

  <footer ...>
  </footer>

</body>
</html>
```

This is easy to adapt to Franklin by defining a `_layout/head.html` to contain
everything above `<div class="content">` and `_layout/foot.html` to
contain everything below it.

#### Content

The content is where the Markdown converted to HTML will go.
Here, it's going to be most of what's in the `<main>` part.
Roughly speaking things above of that will go in `head.html` and thing below the
closing tag will go in `foot.html`.

If we inspect it more closely, we will see that the *landing* page looks like

```html
<main aria-label="Content">
  <div id="content-container" class="container">
      <header class="pt-3 mb-3">
          <p>Posts<p>
      </header>
      <div id="content">

...
```

whereas the *about* page looks like

```html
<main aria-label="Content">
  <article>
    <header class="pt-4 pb-3">
        <h1>About</h1>
    </header>
    <div id="content">
...
```

and a *post* page looks like

```html
<main aria-label="Content">
  <div id="content-container" class="container">
    <article itemscope itemtype="http://schema.org/BlogPosting">
      <header class="pt-4 pb-3">
        <h1 itemprop="name headline">Welcome to minima-reboot</h1>
          <p class="text-secondary">
            <time datetime="2017-12-26T00:00:00+00:00" itemprop="datePublished">
              Dec 26, 2017
            </time>
          </p>
      </header>
      <div class="text-justify" itemprop="articleBody" id="content">
```

So there are some differences that we need to take into account.

#### Head (1)

In the head we basically put everything that's above the `<main>` block as
well as the start of that main block with conditionals based on the differences
highlighted in the previous point.

Let's start with the simple bit first.
In most layouts, there's a recurring part that you find on pretty  much all pages "as is".

In the current case, everything above `<main>` is pretty much like this so you can just
copy paste it in the `head.html`. A couple of points things to bear in mind (illustrated further below):

* for assets (`.js`, `.css`), figure out whether you want or need to host them statically, if so download them and put them in the `_css` or `_libs` and adjust the references accordingly,
* for meta tags, you will typically want to use [page-variables](/syntax/vars+funs/) to make
it (much) easier to maintain them from the `config.md` file,

In our case, to simplify the presentation, we will make very asset (css, js, images) static.
You can choose to do this or not, there are pros and cons in both cases (e.g. see [this SO post](https://stackoverflow.com/questions/26192897/should-i-use-bootstrap-from-cdn-or-make-a-copy-on-my-server)).

So for instance we replace

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.1/dist/css/bootstrap.min.css" ...>
```

by

```html
<link rel="stylesheet" href="/css/bootstrap.min.css">
```

after having saved the CSS at `_css/bootstrap.min.css`.

In terms of the point on meta tags, we replace for instance

```html
<meta name="author" content="GitHub User" />
```

by

```html
<meta name="author" content="{{author}}" />
```

and in `config.md` we correspondingly put

```plaintext
+++

...
author = "The Author"
...

+++
```

#### Head (2) (XXX)

Now let's turn to the different ways to open the main part.
We just need to add conditionals via `ispage` to check that the relevant block
is applied on the relevant page(s).

```html
<main aria-label="Content">
  <div id="content-container" class="container">

{{ispage index.html}}  <!-- specific to the landing page -->
  <header class="pt-3 mb-3">
    <p> {{header}} <p>
  </header>
  <div id="content">
{{end}}

{{ispage about.html}} <!-- specific to the about page -->
  <article>
    <header class="pt-4 pb-3">
        <h1>{{header}}</h1>
    </header>
    <div id="content">
{{end}}

{{ispage posts/*}}
  {{ispage posts/index.html}} <!-- posts landing page -->
  {{else}} <!-- specific posts -->
    <article itemscope itemtype="http://schema.org/BlogPosting">
      <header class="pt-4 pb-3">
        <h1 itemprop="name headline">{{header}}</h1>
          <p class="text-secondary"> <time datetime="" itemprop="datePublished"> </time> </p>
      </header>
      <div class="text-justify" itemprop="articleBody" id="content">
  {{end}}
{{end}}
```

#### Foot

The process for `foot.html` is identical except that we consider what's below `</main>` and
we have to close what was open in the main part (with the same conditionals).
So we end up with something like

```html
{{ispage index.html}}  <!-- specific to the landing page -->
{{end}}

{{ispage about.html}} <!-- specific to the about page -->
{{end}}

{{ispage posts/*}}
  {{ispage posts/index.html}} <!-- posts landing page -->
  {{else}} <!-- specific posts -->
  {{end}}
{{end}}

</main> <!-- always -->
<footer id="site-footer">
  ...
</footer>
</body>
</html>
```



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
