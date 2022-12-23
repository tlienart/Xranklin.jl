# Gaston

<!-- 
ASsuming the .github also gets moved with action checkout 
then could actually parse the YML and extract the dependency bit so that things would stay in sync.
 -->

```!
import Downloads
lib = "gaston"
base_url = "https://tlienart.github.io/Xranklin.jl/"
spec_url = "ttfx/$(lib)/index.html"

@show "$base_url$spec_url"

# h = read(Downloads.download("$base_url$spec_url"), String)
# "~~~$h~~~"
```