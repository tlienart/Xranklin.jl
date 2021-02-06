using Xranklin

OUTPUT = normpath(joinpath(@__FILE__, "..", "_output"))
INPUT_MD = normpath(joinpath(@__FILE__, "..", "integration", "test_md_pages"))

isdir(OUTPUT) || mkpath(OUTPUT);

for file in readdir(INPUT_MD)
    md = read(joinpath(INPUT_MD, file), String)
    open(joinpath(OUTPUT, splitext(file)[1] * ".html"), "w") do f
        write(f, html(md))
    end
end
