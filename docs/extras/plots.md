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
  min-width: 450px;
}

.code-stdout {
  visibility: hidden;
}
</style>
~~~

## Overview

Julia has many packages that offer plotting capacity and you can use any of them in Franklin as long as the resulting plot is showable as SVG or PNG or has a [custom show](/syntax/code/#custom_show) method.

One key difficulty is that if you want your site to be built remotely (e.g. by [GitHub Action][GA]) then you need to ensure that the relevant dependencies (if any) are installed to enable this.
We discuss this for each of the plotting package below.
Remember that you also **must** add the relevant plotting library to your website environment using [Pkg.jl](https://github.com/JuliaLang/Pkg.jl) e.g. with something like

```julia
using Pkg; Pkg.add("Plots")
```

\note{
  If you use another approach to remotely build your website, for instance with GitLab, please consider opening an issue discussing how to adapt the GitHub-specific instructions. It should be fairly similar.
}

In order to avoid name clashes, all packages in the code snippets below are `import`ed and so all function calls are of the form `Plots.plot`.
You don't need to do this if you're using a single plotting library of course.

## Plots.jl

[Plots.jl](https://github.com/JuliaPlots/Plots.jl) is one of the most common plotting package used.
It is pretty easy to use and has [great documentation](https://docs.juliaplots.org/stable/).
The default backend ([GR.jl](https://github.com/jheinen/GR.jl)) works pretty well and is fairly quick.

Relative to Franklin, objects plotted via functions like `Plots.plot` are showable to SVG so it's particularly simple to use this plotting library with Franklin.

\lskip

\showmd{
  ```!
  import Plots

  x = range(-1, 1, length=300)
  y = @. sinc(x) * cos(x) * exp(-1/x^2)

  Plots.plot(x, y, label="Hello", size=(500, 300))
  ```
}

### Plots with GA

The GR backend requires to have `qt5-default` installed and to run the Julia command with [`xvfb`](https://en.wikipedia.org/wiki/Xvfb).
So you will need to have a line in your GitHub Action script like

```yml
run: |
     sudo apt-get update -qq
     sudo apt-get install -y qt5-default
```

and you will also need to prefix the call to Julia for the actual website building with `xvfb-run`:

```yml
run: xvfb-run julia -e 'using Pkg; ...'
```

The overhead of installing `qt5-default` on GA is a bit under 30s, and the time to precompile the Plots package and get the first plot on GA is around 1 min at the time of writing.

Remember to also add `Plots` to your environment.


## CairoMakie

CairoMakie is the Cairo backend for [Makie.jl](https://github.com/JuliaPlots/Makie.jl).
It is geared towards high-quality 2D plotting.
See also the Franklin-based [Makie documentation](https://makie.juliaplots.org/stable/).

\showmd{
```!
  import CairoMakie
  CairoMakie.activate!()

  x  = range(0, 10, length=100)
  y1 = sin.(x)
  y2 = cos.(x)

  CairoMakie.scatter(x, y1,
    color      = :red,
    markersize = range(5, 15, length=100)
  )
  CairoMakie.scatter!(x, y2,
    color    = range(0, 1, length=100),
    colormap = :thermal
  )

  CairoMakie.current_figure()
  ```
}

The `current_figure()` at the end returns an object showable as SVG which is what is displayed above.

For many more examples using this package, see the wonderful [Beautiful Makie](https://lazarusa.github.io/BeautifulMakie/)
site by [Lazaro Alonso](https://github.com/lazarusA) and also based on Franklin.

### CairoMakie with GA

You don't need to install anything specific in your GA script but remember to add `CairoMakie` to your environment.

## WGLMakie

WGLMakie is the WebGL backend for [Makie.jl](https://github.com/JuliaPlots/Makie.jl).
See also the [docs](https://makie.juliaplots.org/dev/documentation/backends/wglmakie/).

Combined with [JSServe.jl](https://github.com/SimonDanisch/JSServe.jl) it can produce HTML with Javascript for interactive plots.

(Safari users will need to enable WebGL, see [link in the WGLMakie docs](https://makie.juliaplots.org/stable/documentation/backends/wglmakie/#troubleshooting))

\showmd{
  ```!wgl
  import WGLMakie, JSServe
  WGLMakie.activate!()

  <|(io, o) = show(io, MIME"text/html"(), o)

  io = IOBuffer()

  io <| JSServe.Page(exportable=true, offline=true)
  io <| WGLMakie.scatter(1:4)
  io <| WGLMakie.surface(rand(4,4))
  io <| JSServe.Slider(1:3)

  String(take!(io))
  ```

  \htmlshow{wgl}
}

### WGLMakie with GA

You don't need to install anything specific in your GA script but remember to add `WGLMakie` to your environment.

## PyPlot

[PyPlot.jl](https://github.com/JuliaPy/PyPlot.jl)

\showmd{
  ```!
  import PyPlot

  x = range(-1, 1, length=300)
  y = @. sinc(x) * exp(-1/x^2)

  PyPlot.figure(figsize=(6, 4))
  PyPlot.plot(x, y, lw=3, label="Hello")
  PyPlot.legend()
  PyPlot.gcf()
  ```
}

Note how we need to use `gcf()` here so that the result of the code cell &mdash; a figure &mdash;
is showable as a SVG.


## PGFPlotsX

Requires you to have `lualatex` installed (also on CI) + `pdf2svg`

\showmd{
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
  ```
}

## PlotlyJS

\showmd{
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
  opath = mkpath(joinpath(Utils.path(:site), "assets", "plotlyfigs"))
  PlotlyJS.savejson(p, joinpath(opath, "ex.json"));
  ```

  ~~~
  <div id="foobar"></div>

  <script>
  graphDiv = document.getElementById("foobar");
  plotlyPromise = PlotlyJS_json(graphDiv, "/{{> ifelse($_final, $base_url_prefix, "" ) }}assets/plotlyfigs/ex.json")
  </script>
  ~~~
}
