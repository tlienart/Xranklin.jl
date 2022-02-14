+++
header = "Building websites with Franklin.jl"
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
Franklin is a simple, customisable, static site generator with a focus on technical blogging.
@@

## Key features

_click on the '&check;' sign to know more_

@@flist
* \goto{/syntax/markdown/} Augmented markdown allowing definition of LaTeX-like commands,
* \goto{/syntax/divs-commands/} Easy inclusion of user-defined div-blocks,
* \goto{/syntax/divs-commands/} Maths rendered via [KaTeX](https://katex.org/), code via [highlight.js](https://highlightjs.org) both can be pre-rendered,
* \goto{/code/} Can live-evaluate Julia code blocks,
* \goto{/workflow/#creating_your_website} Live preview of modifications,
* \goto{/workflow/#publication_step} Simple publication step to deploy the website
@@
