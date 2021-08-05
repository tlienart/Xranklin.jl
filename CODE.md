# CODE

When an executable code cell is seen:

- stdout + stderr is redirected to a file (`out_path`)
- the result (Julia value which may be `nothing`) is in the code pair `(code=code, result=result)`; if the cell had an error, the result is necessarily `nothing`. Let's say the result has type `R`.

The expected output to be displayed notebook style is

```
[STDOUT + light STDERR]
[hard STDERR] || [RESULT DISPLAY]
```

where

* `STDOUT` is filled by things like `@show` or `println`
* `light STDERR` is filled by things like `@warn` (non breaking)
* `hard STDERR` is the message corresponding to a breaking error

and finally `RESULT DISPLAY` would be the action + string corresponding to

```
show(::IO, ::MIME"text/html", res::R)
```

which, in order of precedence,

* calls `show(::IO, ::MIME"text/html", res::R)` implemented by the user in `utils.jl`
* calls a fallback `show(::IO, ::MIME"text/html", res::R)` implemented by Franklin
* calls `show(::IO, res)` whatever that may be

Franklin should not take the responsibility to implement too many fallbacks, but it could implement a couple for the sake of showing how things could be done. One that may be convenient is to show figures (though that may quickly become annoying to support all backends).

```julia
function Base.show(io::IO, ::MIME("text/html"), res::R)
    if Base.showable("image/svg+xml", res)
        # note: in pyplot this is false even though it can, see
        # https://github.com/JuliaPy/PyPlot.jl/blob/52a83c88fc10f159d044db5e14563f524562898b/src/PyPlot.jl#L92-L95
        open("somefile.svg", "w") do outf
            Base.show(outf, MIME("image/svg+xml"), res)
        end
        println(io, """<img src="somefile.svg" />""")
    elseif Base.showable("image/png", res)
        open("somefile.png", "w") do outf
            Base.show(outf, MIME("image/png"), res)
        end
        println(io, """<img src="somefile.png" />""")
    else
        # generic fallback to plaintext
        Base.show(io, res)
    end
end
```

This is incomplete and untested. Note that for users who'd want to have their own ALT or whatever, they can always write their own HTML at the bottom of the code cell or call a function that does this for them...
