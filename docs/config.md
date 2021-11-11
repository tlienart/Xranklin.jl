+++


author = "Thibaut Lienart"

# Layout
layout_page_foot = ""


+++

\newcommand{\showmd}[1]{
  ~~~
  <fieldset class="md-input">
    <legend class="md-input-legend">markdown</legend>
  ~~~
  `````markdown
  #1
  `````
  ~~~
  </fieldset>
  <fieldset class="md-result">
    <legend class="md-result-legend">result</legend>
  ~~~

  #1

  ~~~</fieldset>~~~
}
