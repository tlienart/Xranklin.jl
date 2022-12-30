+++
showtoc = true
header = "Franklin and Plots in Julia"
menu_title = header
hascode = true
+++

~~~
<style>
img.code-figure {
  max-width: 600px;
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

### Overhead

In the table below we list the time taken from starting a GA deployment to displaying a meaningful plot.

* **Time 1** is effectively the _time to first plot_ i.e. the time it takes to run a simple code cell that plots something meaningful,
* **Time 2** is a total build time including the set up of dependencies with GA on a simple page that runs and shows the plot.

Note that the exact time you get in your case will depend on GA and so you should take these numbers as indicators rather than an exact figure.

~~~
<style>
.pure-table {margin:auto;}
</style>
~~~

\lskip

| Package | Example | ΔT1 (sec) ~~~<th>ΔT2 (min)</th>~~~   |
| ---------------- | ------ | --------------- |
| [CairoMakie.jl](https://github.com/JuliaPlots/CairoMakie.jl)     | [➡️](#cairomakie)   | {{ttfx cairomakie}}   |
| [Gadfly.jl](https://github.com/GiovineItalia/Gadfly.jl)          | [➡️](#gadfly)       | {{ttfx gadfly}}       |
| [Gaston.jl](https://github.com/mbaz/Gaston.jl)                   | [➡️](#gaston)       | {{ttfx gaston}}       |
| [PGFPlots.jl](https://github.com/JuliaTeX/PGFPlots.jl)           | [➡️](#pgfplots)     | {{ttfx pgfplots}}     |
| [PGFPlotsX.jl](https://github.com/KristofferC/PGFPlotsX.jl)      | [➡️](#pgfplotsx)    | {{ttfx pgfplotsx}}    |
| [Plots.jl](https://github.com/JuliaPlots/Plots.jl) (GR)  | [➡️](#plots)        | {{ttfx plots}}        |
| [PyPlot.jl](https://github.com/JuliaPy/PyPlot.jl)                | [➡️](#pyplot)       | {{ttfx pyplot}}       |
| [UnicodePlots.jl](https://github.com/JuliaPlots/UnicodePlots.jl) | [➡️](#unicodeplots) | {{ttfx unicodeplots}} |
| [WGLMakie.jl](https://github.com/JuliaPlots/WGLMakie.jl)         | [➡️](#wglmakie)     | {{ttfx wglmakie}}     |

\lskip

Lastly, note that if the pages on which you have plots don't change and that you use the cache, these pages will be skipped at build time and you won't have to pay the full overhead (only the installation of the dependencies but that's always under 1 min).

## Examples

{{add_plot_headings}}

### CairoMakie

{{plotlib cairomakie}}

### Gadfly

{{plotlib gadfly}}

### Gaston

{{plotlib gaston}}

### PGFPlots

{{plotlib pgfplots}}

### PGFPlotsX

{{plotlib pgfplotsx}}

### Plots

{{plotlib plots}}

### PyPlot

{{plotlib pyplot}}

### UnicodePlots

{{plotlib unicodeplots}}

### WGLMakie

{{plotlib wglmakie}}


