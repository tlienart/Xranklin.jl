+++
showtoc = true
header = "Using and adapting an external layout"
menu_title = "Adapting a layout"
+++

## Overview

Remember that layouts can quickly become complicated especially if you want them to work on multiple devices flawlessly: does the layout work on all screen ratios? on all browsers? don't forget that the aim should be to publish great content and not spend hundreds of hours trying to figure out why some menu doesn't properly collabse in narrow mode.

Starting from an established layout that you've found somewhere and/or using a CSS template will help a lot in this respect.
Designing a layout from scratch, if you don't have a lot of webdev experience, can be pretty painful.

## Tips and tricks

### Organising layout files

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
