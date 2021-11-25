+++


author = "Thibaut Lienart"

# General Layout
layout_page_foot = ""
content_tag = ""
menu = [
  "Overview"  => "/overview/",
  "Syntax"    => "/syntax/",
  "Layout"    => "/layout/",
  "Context"   => "/context/",
  "FAQs"      => "/faq/"
]

# Page layout
showtoc = false

# Misc
meta_description = "Franklin"


+++


\newcommand{\fieldset}[3]{
  ~~~
  <fieldset class="#1"><legend class="#1-legend">#2</legend>
  ~~~
  #3
  ~~~
  </fieldset>
  ~~~
}

<!--
  Show markdown + what it looks like in a box
-->
\newcommand{\showmd}[1]{
  \fieldset{md-input}{markdown}{
    `````markdown
    #1
    `````
  }
  <!--
  XXX keep extra line skip otherwise the blockquote and the
  showmd environment blend and it's ugly!
   -->
  \fieldset{md-result}{result}{
    ~~~~~~

    #1

    ~~~~~~
  }
}

<!--
  Note about difference with CommonMark
-->
\newcommand{\cmdiff}[1]{
  \fieldset{cm-diff}{&ne; CommonMark}{
    #1
  }
}

<!--
  Tip
-->
\newcommand{\tip}[1]{
  \fieldset{tip}{🚀 Tip}{
    #1
  }
}


[juliaweb]: https://julialang.org
