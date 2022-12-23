# Gaston

<!-- 
ASsuming the .github also gets moved with action checkout 
then could actually parse the YML and extract the dependency bit so that things would stay in sync.
 -->

```julia:ex
import Downloads
lib = "gaston"
url = "https://raw.githubusercontent.com/tlienart/Xranklin.jl/gh-ttfx/ttfx/$lib/index.html"
read(Downloads.download(url), String)
```

\htmlshow{ex}
<!-- 
http://localhost:8000/Xranklin.jl/ttfx/gaston/assets/index/figs-html/__autofig_11787316828808756648.svg -->