<!--

Currently hidden, this might be better in a separate demo page.

 -->

<!-- +++
showtoc = true
header = "Plots"
menu_title = header
+++

~~~
<style>
img.code-figure {
  max-width: 600px;
  min-width: 350px;
}
</style>
~~~

This is a follow up from code but with more examples to do with plotting specifically.

\note{
  While you can use packages as you want, remember that if you use CI (e.g. GitHub action)
  then all these packages must be installed every time CI is run which can take a while
  if you have a lot of big packages.

  For Plots for instance, PyPlot is nice because the installation from scratch takes little
  time.
}

## Plots

\showmd{
  ```!
  import Plots
  x = range(-1, 1, length=250)
  y = @. sinc(x) * exp(-1/x^2)

  Plots.plot(x, y, label="Hello", size=(500, 500))
  ```
}
## PyPlot

\showmd{
  ```!
  import PyPlot

  PyPlot.figure(figsize=(8, 6))
  PyPlot.plot(x, y, lw=3, label="Hello")
  PyPlot.axis("off")
  PyPlot.legend()
  PyPlot.gcf()
  ```
}

Note how we need to use `gcf()` here so that the result of the code cell &mdash; a figure &mdash;
is showable as a SVG.


## PGFPlotsX

Requires you to have `lualatex` installed (also on CI) + `pdf2svg`

```!
using LaTeXStrings
using PGFPlotsX
@pgf Axis(
    {
        xlabel = L"x",
        ylabel = L"f(x) = x^2 - x + 4"
    },
    Plot(
        Expression("x^2 - x + 4")
    )
)
```

## PlotlyJS

~~~
<script src="/libs/plotly/plotly.min.js"></script>
<script>
    const PlotlyJS_json = async (div, url) => {
      response = await fetch(url)
      fig = await response.json()
      if (typeof fig.config === 'undefined') { fig["config"]={} }
        delete fig.layout.width
        delete fig.layout.height
        fig["layout"]["autosize"] = true
        fig["config"]["autosizable"] = true
        fig["config"]["responsive"] = true
        fig.config["scrollZoom"] = false
        delete fig.config.staticPlot
        delete fig.config.displayModeBar
        delete fig.config.doubleClick
        delete fig.config.showTips
        Plotly.newPlot(div, fig);
    }
  </script>
~~~

```!
using PlotlyJS
p=plot(
     scatter(x=1:10, y=rand(10), mode="markers"),
     Layout(title="Responsive Plots")
     )
opath = mkpath(joinpath(Utils.path(:site), "assets", "figs"))
PlotlyJS.savejson(p, joinpath(opath, "plotlyjs_ex.json"));
```

~~~
<div id="foobar"></div>

<script>
graphDiv = document.getElementById("foobar");
plotlyPromise = PlotlyJS_json(graphDiv, "/assets/figs/plotlyjs_ex.json")
</script>
~~~ -->