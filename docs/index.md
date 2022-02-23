+++
header = "Building websites with Franklin"
+++

\newcommand{\goto}[1]{
  ~~~
  <a href="!#1" id="goto">
    <span id="check">&check;</span>
    <span id="arrow"><b>&rarr;</b></span>
  </a>
  ~~~
}

~~~
<style>
.sub-header {
  font-size: 1.5em;
  font-weight: 300;
}
.flist p {
  display:inline;
}
.flist ul {
  list-style: none;
  padding-left: 1em;
}
.flist a#goto {
  padding-right: 10px;
  margin-left: -15px;
}
.flist a#goto #arrow{
  display:none;
}
.flist a#goto:hover #check {
  display: none;
}
.flist a#goto:hover #arrow {
  display: inline;
}
</style>
~~~

@@sub-header
Franklin.jl is a simple, customisable, static site generator with a focus on technical blogging.
@@

😓💦🚒

## Key features

_click on the '&check;' sign to know more_

@@flist
* \goto{/syntax/basics/} Based on common Markdown syntax,
* \goto{/syntax/extensions/} Multiple extensions to the base Markdown syntax such as the possibility to define LaTeX-like commands or the inclusion of div-blocks,
* \goto{/syntax/extensions/} Maths rendered via [KaTeX](https://katex.org/), code via [highlight.js](https://highlightjs.org) both can be pre-rendered,
* \goto{/syntax/code/} Can live-evaluate Julia code blocks,
* \goto{/workflow/deployment/} Simple publication step to deploy the website
@@

## Quick start

To install Franklin with Julia *≥ 1.5*, in a Julia REPL do

* hit \kbd{]} to enter package mode,
* write `add Franklin` and press \kbd{enter}.

You can then just try it out:

```julia-repl
julia> using Franklin
julia> newsite("mySite", template="pure-sm")
✓ Website folder generated at "mySite" (now the current directory).
→ Use serve() from Franklin to see the website in your browser.

julia> serve()
(...)
✓ LiveServer listening on http://localhost:8000/ ...
  (use CTRL+C to shut down)
```

If you navigate to that URL in your browser, you will see the website.
If you then open `mySite/index.md` in an editor and modify it at will, the changes
will be live-rendered in your browser.

Read more in [Getting Started](/workflow/getting_started/).
