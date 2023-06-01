include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@test_in_dir "_ispage" "ispage paths" begin
   write(FOLDER / "index.md", """
        {{ispage /}}Y1{{end}}
        {{ispage index.html}}Y2{{end}}
        {{ispage /index.html}}Y3{{end}}
        """)
    other = FOLDER / "foo" / "bar.md"
    mkpath(splitdir(other)[1])
    write(other, """
        {{ispage /foo/bar/}}Y1{{end}}
        {{ispage /foo/bar}}Y2{{end}}
        {{ispage foo/bar/}}Y3{{end}}
        {{ispage foo/bar}}Y4{{end}}
        {{ispage /foo/bar/index.html}}Y5{{end}}
        """)
    serve(FOLDER, single=true)
    c_index   = read(FOLDER / "__site" / "index.html", String)
    for i in 1:3
        @test contains(c_index, "Y$i")
    end
    c_foo_bar = read(FOLDER / "__site" / "foo" / "bar" / "index.html", String) 
    for i in 1:5
        @test contains(c_foo_bar, "Y$i")
    end
end
