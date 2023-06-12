include(joinpath(@__DIR__, "..", "utils.jl"))


nowarn()

@test_in_dir "_anchors" "global anchors" begin
    write(joinpath(FOLDER, "a.md"), """
        Hello

        # anchor a.a

        # anchor a.b
        """)

    write(joinpath(FOLDER, "b.md"), """
        using

        * [a.a](## anchor a.a)
        * [a.b](## anchor a.b)
        """)

    serve(FOLDER, single=true)

    cb = read(joinpath(FOLDER, "__site", "b", "index.html"), String)
    @test contains(cb, """<a href="/a/#anchor_a.a">a.a</a>""")
    @test contains(cb, """<a href="/a/#anchor_a.b">a.b</a>""")

    # issue 178
    write(joinpath(FOLDER, "c.md"), """
        adding an anchor with same name

        # anchor a.a
        """)
    serve(FOLDER, single=true, cleanup=false, clear=true)
    gc = cur_gc()
    # defined in two places    
    @test length(gc.anchors["anchor_a.a"].locs) == 2

    # let's remove one of the places
    rm(joinpath(FOLDER, "c.md"))
    serve(FOLDER, single=true, cleanup=false, clear=true)
    gc = cur_gc()
    @test length(gc.anchors["anchor_a.a"].locs) == 1
end

logall()
