import Pkg
import TOML
import UnicodePlots

ENV["PLIB"]  = "wglmakie"
ENV["DEPS"]  = "deps"
ENV["START"] = "1.672235621765e9"


const PLIBS = Dict{String,String}(
    "cairomakie"   => "CairoMakie",   # dec 28'22
    "gadfly"       => "Gadfly",       # dec 28'22
    "gaston"       => "Gaston",       # dec 28'22
    "gleplots"     => "GLEPlots",     # todo
    "pgfplots"     => "PGFPlots",     # dec 28'22
    "pgfplotsx"    => "PGFPlotsX",    # dec 28'22
    "plots"        => "Plots",        # dec 28'22
    "pyplot"       => "PyPlot",       # dec 28'22
    "unicodeplots" => "UnicodePlots", # dec 28'22
    "wglmakie"     => "WGLMakie"      # dec 28'22
)


function hfun_plot()
    lib = get(ENV, "PLIB", "")
    if lib == "wglmakie"
        html(
            "\\ptic\n```!wgl\n" * 
            read(joinpath(path(:folder), "_$lib.jl"), String) *
            "\n```\n\\htmlshow{wgl}\n\\ptoc\n";
            #
            rpath=lib
        )
    elseif lib in keys(PLIBS)
        html(
            "\\ptic\n```!\n#name:example\n" * 
            read(joinpath(path(:folder), "_$lib.jl"), String) *
            "\n```\n\n\\ptoc\n";
            #
            rpath=lib
        )
    else
        html("Lib '$lib' not resolved yet.")
    end
end


function lx_ptic()
    start = get(ENV, "START", "0")
    lib   = PLIBS[get(ENV, "PLIB", "")]
    deps  = get(ENV, "DEPS", "")

    pg = """
        ```!tic
        # name: tic
        # hideall
        tic_1 = $start
        tic_2 = time()
        ```

        ### $lib

        Setting up dependencies on Github Action:

        $(
            ifelse(
                isempty(deps),
                "",
                """
                ```plaintext
                $deps
                ```
                """
            )
        )

        Package version used in the example:

        ```!
        # name: version
        # hideall
        using Pkg
        using TOML
        using $lib
        TOML.parsefile(joinpath(dirname(pathof($lib)), "..", "Project.toml"))["version"] |> println
        ```

        #### Example
        """
    return html(pg, cur_lc())
end


function lx_ptoc()
    lib = get(ENV, "PLIB", "")
    pg  = """
        #### Timers

        ```!
        # name: timers
        # hideall
        using Dates
        toc = datetime2unix(now())
        # cell exec time in seconds
        δ1  = round( toc - tic_2, digits=2)
        # page build exec time in minutes
        δ2  = round((toc - tic_1) / 60, digits=2)

        ps(s) = joinpath(Utils.path(:site), "assets", "$lib", s)
        write(ps("timer-code"), δ1)
        write(ps("timer-build"), δ2)

        println(\"\"\"
            Code execution time: \$(δ1) seconds.
            Total time taken (setup + build): \$(δ2) minutes.
            \"\"\"
        )
        ```
        """
    return html(pg, cur_lc())
end

function html_show(p::UnicodePlots.Plot)
    td = tempdir()
    tf = tempname(td)
    io = IOBuffer()
    UnicodePlots.savefig(p, tf; color=true)
    p = pipeline(`cat $tf`, `ansi2html -i -l`, io)
    if success(p)
        return "<pre>" * String(take!(io)) * "</pre>"
    end
    return ""
end