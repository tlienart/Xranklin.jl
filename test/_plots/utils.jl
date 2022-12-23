function hfun_plot()
    lib = get(ENV, "PLIB", "")
    if lib in ("gaston",)
        html(
            read(joinpath(path(:folder), "_$lib.md"), String);
            rpath=lib
        )
    else
        html("Lib '$lib' not resolved yet.")
    end
end
