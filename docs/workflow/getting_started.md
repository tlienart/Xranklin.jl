<!--
 LAST REVISION: Jan 24, 2022  (full page ok)
 -->

+++
showtoc = true
header = "Getting Started"
menu_title = header
+++

## Generate a site from a template

To get started with Franklin, use the `newsite` function
in a Julia REPL.
That function will generate a _website folder_ on your computer that's ready
to be built by Franklin, and that you can modify at will:

```
using Franklin
newsite("TestWebsite"; template="hyde")
```

The execution of this command will also move you to that folder (i.e. `cd TestWebsite/`).

The first argument of `newsite` is the title of the folder that will be created,
and moved to (you can change that later).
If you are already in a folder that you previous created for this purpose, just indicate the
current path with `"."`.

The `template=` keyword argument allows you to specify one of the few
[simple templates](https://tlienart.github.io/FranklinTemplates.jl/)
that can get you started with Franklin.
In particular, if you just want a super basic template to experiment with, the
`"sandbox"` template should prove useful.

\note{
  Most of these templates are adapted, simplified versions of common standard
  static site templates.
  They are not meant to be fully polished but should be easy to adjust to your liking
  once you're familiar with how Franklin operates.\\
  Your help to add new templates or make existing ones better is very welcome!
}

## Building and editing the website

Once you have a website folder \emdash e.g. `TestWebsite` \emdash you can start the Franklin
server from within it:

```plaintext
serve()  # or serve("path/to/TestWebsite")

[...]

✓ LiveServer listening on http://localhost:8000/ ...
  (use CTRL+C to shut down)
```

You can now visit your site at `http://localhost:8000` (the page should have been opened automatically in your browser).

At a high level, the `serve` function does the following:

1. builds all your pages in an initial first pass,
1. starts [LiveServer][liveserver] which
  1. starts a browser,
  1. watches files for changes and reloads updated pages.

There's a number of keyword arguments to `serve` which you might find useful, do `?serve`
in your REPL to get the relevant docstring.

### Modifying files

Once the server is running, you can edit the file `index.md` and see the effect it
has in your browser.
If you're familiar with Markdown, this step should hopefully be fairly intuitive.
If you're not, you might want to check out the [Markdown basics](/syntax/basics/).
The `index.md` file also  has a few indications for how to do things which you might
find useful.

Once you have a feel for things, you might want to check out the
Franklin-specific [extensions](/syntax/extensions/) and related topics.


### Interrupting and restarting the server

You can interrupt the server at any time by hitting ~~~<kbd>Ctrl</kbd>~~~ + ~~~<kbd>C</kbd>~~~ in the Julia REPL.
And, of course, you can re-start it with `serve(...)`.

Passing `launch=false` to `serve` can be convenient as you may already have a
browser tab pointing to the right address (e.g. `localhost:8000`) and may not want to open
a new one every time you restart the server.

## Page structure

When using Franklin, it is useful to have a rough understanding of how the HTML pages
are generated.
For a source page with the following Markdown:

```markdown
# Hello

Some **text** here.
```

a HTML page will be generated that looks like this:

```plaintext
┌──────────────────────────────────────────────┐
│ ┌──────────────────┐                         │
│ │ <!doctype html>  │                         │
│ │ <html lang="en"> │                         │
│ │ <head>           │                         │
│ │ ...              │  (_layout/head.html)    │
│ │ </head>          │                         │
│ │ <body>           │                         │
│ │ ...              │                         │
│ └──────────────────┘                         │
│ ┌──────────────────────────────────────────┐ │
│ │ <h1>Hello</h1>                           │ │
│ │ <p>Some <strong>text</strong> here.</p>  │ │
│ └──────────────────────────────────────────┘ │
│ ┌──────────┐                                 │
│ │ ...      │                                 │
│ │ </body>  │          (_layout/foot.html)    │
│ │ </html>  │                                 │
│ └──────────┘                                 │
└──────────────────────────────────────────────┘
```

The top box corresponds to the file `_layout/head.html` in your website folder.
Correspondingly, the bottom box corresponds to the file `_layout/foot.html`.
The middle box is the HTML that is generated by Franklin when converting the source Markdown.

Note that what gets effectively placed at the "top" or "bottom" of your page can be finely controlled
via [page variables](/syntax/vars+funs/) but, for now, the important bit is just to have this simple
high-level view in mind.


### Skeleton structure

Though the `head.html`/`foot.html` approach above is recommended as it allows re-using the
`head.html` and `foot.html` elsewhere, including in raw-HTML pages, by doing

```html
{{insert head.html}}

Your HTML here

{{insert foot.html}}
```

some users might prefer having a single `_layout/skeleton.html` file which describes the structure of pages.
For instance it could look like

```html
<!doctype html>
<html lang="en">
<head> ... </head>
<body>
  {{page_content}}  <!-- this inserts the HTML converted from markdown -->
</body>
</html>
```

and so instead of separating the head, content and foot, it's a single file where you just indicate where the content goes.

If you do have a skeleton file in your `_layout` folder and also have a head and foot files, only the skeleton will be considered.


## Next steps

Now that you have a working website that you can render locally and experiment with,
you should try to further modify the `.md` file(s) in the folder and the `.html` files in the
`_layout` folder and try to get an intuition for how things work.

The rest of the docs is there to help you when things don't work like you would expect them to 😅.
Remember also to:

* join the `#franklin` channel of the [Julia Slack](https://join.slack.com/t/julialang/shared_invite/zt-w0pifg7p-18IUSkZy_WpofNumiTTROQ) to get help with small questions quickly,
* ask questions on the [Julia Discourse](https://discourse.julialang.org/) adding the tag `franklin`, and
* open issues on [the repository][franklin-repo] if you encounter a bug.
