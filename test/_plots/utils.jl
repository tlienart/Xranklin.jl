import Pkg
import TOML

ENV["PLIB"] = "wglmakie"

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
    libk  = get(ENV, "PLIB", "")
    lib   = PLIBS[libk]
    deps  = get(ENV, "DEPS", "")

    pg = """
        ```!
        # name: tic
        # hideall
        ps(s) = joinpath(Utils.path(:site), "assets", "$libk", s)
        tic_1 = $start
        tic_2 = time()
        ;
        ```

        #### Setup

        Version of the package used in the example:

        ```!
        # name: version
        # hideall
        using Pkg
        using TOML
        using $lib
        TOML.parsefile(joinpath(dirname(pathof($lib)), "..", "Project.toml"))["version"] |> println
        ```

        $(
            ifelse(
                isempty(deps),
                """
                This package does not require installing dependencies on GitHub Action.
                """,
                """
                To install dependencies on Github Action add a `run` step prior to the build with:
                ```plaintext
                $deps
                ```
                """
            )
        )

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

        write(ps("timer-code"), δ1)
        write(ps("timer-build"), δ2)

        print(\"\"\"
            Code execution time: \$(δ1) seconds.
            Total time taken (setup + build): \$(δ2) minutes.
            \"\"\"
        )
        ```
        """
    return html(pg, cur_lc())
end


if get(ENV, "PLIB", "") == "unicodeplots"
    import UnicodePlots
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
end