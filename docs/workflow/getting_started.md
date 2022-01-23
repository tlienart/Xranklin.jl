+++
showtoc = true
header = "Getting Started"
menu_title = header
+++

## Starting with a template

To get started with Franklin, use the `newsite` function
in a Julia REPL.
That function will generate a _website folder_ on your computer that's ready
to be built by Franklin, and that you can modify at will:

```
using Franklin
newsite("TestWebsite"; template="hyde")
```

The execution of this command will also move you to that folder (i.e. `cd TestWebsite`).

The first argument of `newsite` is the title of the folder that will be created,
and moved to.
You can change it later depending on what kind of [deployment](/workflow/deployment/)
you want to do.

The `template=` keyword argument allows you to specify one of the few
[simple templates / themes](https://tlienart.github.io/FranklinTemplates.jl/)
that can get you started with Franklin.
If you just want a super basic template to experiment with, you may find
the `"sandbox"` template useful.

\note{
  Most of these templates are simplified, adapted version of common standard
  static site templates.
  They are not meant to be very polished but should be easy to adjust to your liking
  once you're familiar with how Franklin operates.\\
  Your help to add new templates or make existing ones better is very welcome!
}

## Running the server

Once you have a website folder, say `TestWebsite`, you can start the Franklin
server from within it:

```plaintext
serve()

[...]

✓ LiveServer listening on http://localhost:8000/ ...
  (use CTRL+C to shut down)
```

If you are outside of your website folder, you can also do `serve("path/to/TestWebsite")`.
You can now visit your site at `http://localhost:8000` (the page should have been opened automatically in your browser).

At a high level, the `serve` function does the following:

1. looks at your config files,
1. builds all your pages in a "_first pass_",
1. starts [LiveServer][liveserver] which
  1. starts a browser,
  1. watches your files for changes and, upon changes, re-builds the relevant page(s) and refreshes the browser.

There's a number of keyword arguments to `serve` which you might find useful, do `?serve`
to read the relevant docstring.

### Modifying files

Once the server is running, you can edit the file `index.md` and try modifying it to
see the effect it has in the browser.
If you're familiar with Markdown, this step should hopefully be fairly intuitive.
The file itself has indications for how to do things, and you should try it out to get
a feel for things!

If you want help with the [syntax](/syntax/basics/) click on the relevant links in the menu.

### Interrupting and restarting the server

You can interrupt the server at any time by hitting ~~~<kbd>Ctrl</kbd>~~~ + ~~~<kbd>C</kbd>~~~ in the Julia REPL.
And, of course, you can then re-start it with `serve(...)` again.

Passing `launch=false` to `serve` can be convenient in this case as you may already have a
browser tab pointing to `localhost:8000` and may not want to open a new one every time you
restart the server.

## Page structure

When using Franklin, it is useful to understand how the HTML pages are generated.
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
via [page variables](/syntax/vars+funs/) but, for now, the important bit is just to have this general understanding of how the HTML pages are generated.


## Next steps

Now that you have a working website that you can render locally and experiment with,
you should try to modify the `.md` file(s) in the folder and the `.html` files in the
`_layout` folder and try to get an intuition for how things work.

The rest of the docs is there to help you when things don't work like you would expect them to 😅.
Remember also to:

* join the `#franklin` channel of the [Julia Slack](https://join.slack.com/t/julialang/shared_invite/zt-w0pifg7p-18IUSkZy_WpofNumiTTROQ) to get help quickly,
* ask questions on the [Julia Discourse](https://discourse.julialang.org/) adding the tag `franklin`,
* open issues on [the repository][franklin-repo] if you encounter a bug.
