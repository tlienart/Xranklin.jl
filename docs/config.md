+++


author = "Thibaut Lienart"

# General Layout
layout_page_foot = ""

# Page layout
mintoclevel = 2


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
