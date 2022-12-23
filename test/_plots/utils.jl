function hfun_plot()
    lib = lowercase(get(ENV, "PLIB", ""))
    if lib in ("gaston",)
        html(read("_$lib.md", String))
    else
        html("Lib '$lib' not resolved yet.")
    end
end