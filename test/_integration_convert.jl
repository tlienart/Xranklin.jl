using Xranklin

function itest(
            files=String[];
            do_html=true, do_latex=true, compile=false, show_html=false
        )
    @assert success(`lualatex -v`) "lualatex must be available to Julia for this to work"

    INTEGRATION = normpath(joinpath(@__FILE__, "..", "_integration"))
    OUTPUT      = normpath(joinpath(@__FILE__, "..", "_output"))
    INPUT_MD    = joinpath(INTEGRATION, "test_md_pages")
    ASSETS      = joinpath(INTEGRATION, "assets")

    isdir(OUTPUT) && rm(OUTPUT, recursive=true)
    mkpath(OUTPUT)

    # HEAD / FOOT ---------------------------------------------

    head_html = read(joinpath(ASSETS, "head.html"), String)
    foot_html = read(joinpath(ASSETS, "foot.html"), String)

    head_latex = read(joinpath(ASSETS, "head.tex"), String)
    foot_latex = read(joinpath(ASSETS, "foot.tex"), String)

    cp(joinpath(ASSETS, "katex"), joinpath(OUTPUT, "katex"))
    cp(joinpath(ASSETS, "jlcode.sty"), joinpath(OUTPUT, "jlcode.sty"))
    cp(joinpath(ASSETS, "index.html"), joinpath(OUTPUT, "index.html"))

    # ---------------------------------------------------------

    for file in readdir(INPUT_MD)
        if !isempty(files) && splitext(file)[1] ∉ files
            continue
        end
        md = read(joinpath(INPUT_MD, file), String)
        start = time()
        do_html && open(joinpath(OUTPUT, splitext(file)[1] * ".html"), "w") do f
            write(f, head_html * html(md) * foot_html)
        end
        elapsed = round(Int, (time() - start) * 1000)
        do_html && println("html/δt=$(elapsed)ms ($file)")
        start = time()
        do_latex && open(joinpath(OUTPUT, splitext(file)[1] * ".tex"), "w") do f
            write(f, head_latex * latex(md) * foot_latex)
        end
        elapsed = round(Int, (time() - start) * 1000)
        do_latex && println("latex/δt=$(elapsed)ms ($file)")
        compile && begin
            bk = pwd()
            try
                cd(OUTPUT)
                name = splitext(file)[1]
                run(`lualatex $name`)
            catch ErrorException
            finally
                cd(bk)
            end
        end
    end
    if show_html
        LiveServer.serve(dir=OUTPUT, launch_browser=true)
    end
end
