function hfun_plot()
    lib = get(ENV, "PLOTLIB", "")
    if lib in ("gaston",)
        html(read("_$lib.md", String))
    else
        html("Lib '$lib' not resolved yet.")
    end
end