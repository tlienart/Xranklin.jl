+++
showtoc = true
header = "Using and adapting an external layout"
menu_title = "Adapting a layout"
+++

## Overview
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
