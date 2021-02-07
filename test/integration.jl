using Xranklin
# using Test

INTEGRATION = normpath(joinpath(@__FILE__, "..", "integration"))
OUTPUT = normpath(joinpath(@__FILE__, "..", "_output"))
INPUT_MD = joinpath(INTEGRATION, "test_md_pages")
ASSETS = joinpath(INTEGRATION, "assets")

isdir(OUTPUT) && rm(OUTPUT, recursive=true)
mkpath(OUTPUT)

head_html = read(joinpath(ASSETS, "head.html"), String)
foot_html = read(joinpath(ASSETS, "foot.html"), String)

head_latex = read(joinpath(ASSETS, "head.tex"), String)
foot_latex = read(joinpath(ASSETS, "foot.tex"), String)

for file in readdir(INPUT_MD)
    md = read(joinpath(INPUT_MD, file), String)
    open(joinpath(OUTPUT, splitext(file)[1] * ".html"), "w") do f
        write(f, head_html * html(md) * foot_html)
    end
    open(joinpath(OUTPUT, splitext(file)[1] * ".tex"), "w") do f
        write(f, head_latex * latex(md) * foot_latex)
    end
    bk = pwd()
    cd(OUTPUT)
    name = splitext(file)[1]
    run(`lualatex $name --shell-escape`)
    cd(bk)
end
