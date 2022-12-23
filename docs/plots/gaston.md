# Gaston

<!-- 
ASsuming the .github also gets moved with action checkout 
then could actually parse the YML and extract the dependency bit so that things would stay in sync.
 -->

```julia:ex
import Downloads
lib = "gaston"
bgh = "https://raw.githubusercontent.com/tlienart/Xranklin.jl/gh-plots/$lib"
url = "$bgh/index.html"
h = read(Downloads.download(url), String)
replace(h,
    r"src=\".*?\/figs-html\/(.*)\.svg\"" =>
    SubstitutionString("src=\"$bgh/assets/$lib/figs-html/\\1.svg\"")
)
```

\htmlshow{ex}