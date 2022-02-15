<!--

Last edit: Feb 15

* PyPlot.jl
* Plots.jl
* Makie - CairoMakie
* Makie - GLMakie
* Makie - WGLMakie
* PG

 -->

+++
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

.code-stdout {
  visibility: hidden;
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

Prepare something

```!
x = range(-1, 1, length=250)
y = @. sinc(x) * exp(-1/x^2);
```

## PyPlot

\showmd{
  ```!
  import PyPlot

  PyPlot.figure(figsize=(6, 4))
  PyPlot.plot(x, y, lw=3, label="Hello")
  PyPlot.legend()
  PyPlot.gcf()
  ```
}

Note how we need to use `gcf()` here so that the result of the code cell &mdash; a figure &mdash;
is showable as a SVG.



## Plots

\showmd{
  ```!
  import Plots

  Plots.plot(x, y, label="Hello", size=(500, 300))
  ```
}

<!-- ## PGFPlotsX

Requires you to have `lualatex` installed (also on CI) + `pdf2svg`

```!
using LaTeXStrings
import PGFPlotsX
PGFPlotsX.@pgf PGFPlotsX.Axis(
    {
      xlabel = L"x",
      ylabel = L"f(x) = x^2 - x + 4"
    },
    PGFPlotsX.Plot(
      PGFPlotsX.Expression("x^2 - x + 4")
    )
)
``` -->
<!--
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
import PlotlyJS
p=PlotlyJS.plot(
    PlotlyJS.scatter(x=1:10, y=rand(10), mode="markers"),
    PlotlyJS.Layout(
      title="Responsive Plots"
    )
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
~~~

## CairoMakie

```!
import CairoMakie
CairoMakie.activate!()
x = range(0, 10, length=100)
y1 = sin.(x)
y2 = cos.(x)

CairoMakie.scatter(x, y1, color = :red, markersize = range(5, 15, length=100))
CairoMakie.scatter!(x, y2, color = range(0, 1, length=100), colormap = :thermal)

CairoMakie.current_figure()
```

For many more, see the wonderful [Beautiful Makie](https://lazarusa.github.io/BeautifulMakie/)
site by [Lazaro Alonso](https://github.com/lazarusA).

## WGLMakie

(Safari users will need to enable WebGL, see [link in the WGLMakie docs](https://makie.juliaplots.org/stable/documentation/backends/wglmakie/#troubleshooting))

```!wgl
import WGLMakie, JSServe
WGLMakie.activate!()

io = IOBuffer()
show(io, MIME"text/html"(), JSServe.Page(exportable=true, offline=true))
show(io, MIME"text/html"(), WGLMakie.scatter(1:4))
show(io, MIME"text/html"(), WGLMakie.surface(rand(4,4)))
show(io, MIME"text/html"(), JSServe.Slider(1:3))
String(take!(io))
```

\htmlshow{wgl} -->
