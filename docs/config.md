<!--
Notes:

- KaTeX version = 0.15.1 (changed Jan'22)
- HL version = 11.3.1
 -->

+++


author = "Thibaut Lienart"

# Base URL prefix when live
base_url_prefix = "Xranklin.jl"

# General Layout
layout_page_foot = ""
content_tag = ""

# Menus + ordering of submenus
menu = [
  "workflow" => [
    "getting_started",
    "page_structure",
    "adapting_layout",
    "folder_structure",
    "deployment",
  ],
  "syntax" => [
                "basics",
                "extensions",
                "code",
                # "plots",
                "vars+funs",
                "utils"
                ],
]

# Page layout
showtoc = false

# Tables
table_class = "pure-table"

# Misc
meta_description = "Franklin"
github = "https://github.com/tlienart/Franklin.jl"

+++


<!-- GLOBAL REFERENCES -->

[juliaweb]: https://julialang.org
[Pure.css]: https://purecss.io/
[hljs]: https://highlightjs.org/
[katex]: https://katex.org/
[mathjax]: https://www.mathjax.org/
[pycall]: https://github.com/JuliaPy/PyCall.jl
[rcall]: https://github.com/JuliaInterop/RCall.jl
[dataframes]: https://github.com/JuliaData/DataFrames.jl
[bootstrap]: https://getbootstrap.com/

<!-- GLOBAL COMMANDS -->

\newcommand{\skip}{
  ~~~
  <p></p>
  ~~~
}

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
  ~~~
  <div class="trim">
  ~~~
  \fieldset{md-input}{markdown}{
    `````plaintext
    #1
    `````
  }
  ~~~
  </div>
  ~~~
  <!--
  XXX keep extra line skip otherwise the blockquote and the
  showmd environment blend and it's ugly!
   -->
  ~~~
  <div class="trim">
  ~~~
    \fieldset{md-result}{result}{
    ~~~~~~

    #1

    ~~~~~~
    }
  ~~~
  </div>
  ~~~
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

<!--
 Todo
-->
\newcommand{\todo}[1]{
  \fieldset{todo}{🚧 To Do}{
    #1
  }
}

<!--
 Note
-->
\newcommand{\note}[1]{
  \fieldset{note}{⚠️ Note}{
    #1
  }
}
