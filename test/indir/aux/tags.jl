include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@test_in_dir "_tags" "base" begin
    write(FOLDER/"config.md", "")
    write(FOLDER/"utils.jl", raw"""
        function hfun_curpagetags()
            pt = get_page_tags(cur_lc())
            io = IOBuffer()
            println(io, "<ul>")
            for (id, name) in pt
                println(io, "<li>$id -- $name</li>")
            end
            println(io, "</ul>")
            return String(take!(io))
        end

        function hfun_ntags()
            at = get_all_tags()
            return repr(length(at))
        end
        """)
    write(FOLDER/"index.md", """
        n-tags: {{ntags}}
        """)

    write(FOLDER/"abc.md", """
        +++
        tags = ["t1", "t2", "t3"]
        barz = 1//2
        +++
        # ABC title
        foo

        {{fill fooz def}}

        {{barz}}

        {{curpagetags}}
        """)
    write(FOLDER/"def.md", """
        +++
        tags = ["t2", "t3", "t4"]
        fooz = 3//5
        +++
        # DEF title
        bar

        {{curpagetags}}
        """)
    build(FOLDER, cleanup=false)

    for f in [
        "__site"/"tags"/"t$i"/"index.html"
        for i in [1,2,3,4]
    ]
        @test isfile(FOLDER/f)
    end

    # t2 has 2 refs
    c = read(FOLDER/"__site"/"tags"/"t2"/"index.html", String)
    for e in (
        "<a href=\"/def/\">DEF title</a>",
        "<a href=\"/abc/\">ABC title</a>"
    )
        @test occursin(e, c)
    end

    # execution of hfuns should be unaffected
    c = read(FOLDER/"__site"/"abc"/"index.html", String)
    for e in (
        "3//5", "1//2", 
    )
        @test occursin(e, c)
    end
    for e in (
        "<li>t$i -- t$i</li>"
        for i in (1,2,3)
    )   
        @test occursin(e, c)
    end

    c = read(FOLDER/"__site"/"def"/"index.html", String)
    for e in (
        "<li>t$i -- t$i</li>"
        for i in (2,3,4)
    )   
        @test occursin(e, c)
    end

    c = read(FOLDER/"__site"/"index.html", String)
    @test occursin("n-tags: 4", c)
end
