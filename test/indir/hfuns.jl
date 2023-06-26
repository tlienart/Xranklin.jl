include(joinpath(@__DIR__, "..", "utils.jl"))

@test_in_dir "_for-estr" "for and estring" begin
    write(FOLDER / "config.md", "")
    write(FOLDER / "index.md", raw"""
        +++
        team = [
        (name="Alice", role="CEO"),
        (name="Bob", role="CTO"),
        (name="Jon", role="Eng")
        ]
        +++
        ~~~
        <ul>
        {{for person in team}}
        <li><strong>{{> $person.name}}</strong>: {{> $person.role}}</li>
        {{end}}
        </ul>
        ~~~
        """)
    build(FOLDER)
    for (name, role) in [
            ("Alice", "CEO"),
            ("Bob", "CTO"),
            ("Jon", "Eng")
        ]
        @test output_contains(FOLDER, "", "<li><strong>$name</strong>: $role</li>")
    end
end

@test_in_dir "_redirect" "redirect" begin
    write(FOLDER / "config.md", "")
    write(FOLDER / "index.md", """
        # Index
        Foo
        """)
    write(FOLDER / "foo.md", """
        {{redirect zoo/zar/zaz.html}}
        Foo
        bar
        """)
    build(FOLDER)

    op = FOLDER / "__site" / "zoo" / "zar" / "zaz.html"
    @test isfile(op)
    @test contains(read(op, String), "url=\"/foo/\"")
    @test isfile(FOLDER / "__site" / "foo" / "index.html")

    write(FOLDER / "bar.md", """
        +++
        redirect = "yoo/yar/yaz"
        +++
        Yoo Yar
        """)
    build(FOLDER)

    op = FOLDER / "__site" / "yoo" / "yar" / "yaz" / "index.html"
    @test isfile(op)
    @test contains(read(op, String), "url=\"/bar/\"")
    @test isfile(FOLDER / "__site" / "bar" / "index.html")
end

@test_in_dir "_slug" "slug" begin
    write(FOLDER / "config.md", "")
    write(FOLDER / "index.md", """
        # Index
        Foo
        """)
    write(FOLDER / "foo.md", """
        {{slug /yar/yaz/}}
        """)
    build(FOLDER)

    # what the path would have been without slug
    op1 = FOLDER / "__site" / "foo" / "index.html"
    # what the path is with a slug
    op2 = FOLDER / "__site" / "yar" / "yaz" / "index.html"

    @test !isfile(op1) # we don't leave the base path
    @test isfile(op2)
end

@test_in_dir "_slug2" "slug+pagination" begin
    write(FOLDER / "config.md", "")
    write(FOLDER / "index.md", "# Index")
    write(FOLDER / "foo.md", raw"""
        +++
        slug = "bar/baz"
        item_list = [
            "* item $i\n"
            for i in 1:20
        ]
        +++

        ABC

        {{paginate item_list 5}}

        DEF
        """)
    build(FOLDER)
    op = FOLDER / "__site" / "bar" / "baz" / "index.html"
    @test isfile(op)
    @test output_contains(FOLDER, "bar/baz", "<li>item 1</li>")
    @test output_contains(FOLDER, "bar/baz/1", "<li>item 1</li>")
    @test output_contains(FOLDER, "bar/baz/2", "<li>item 10</li>")
end

@test_in_dir "_insertmd" "insertmd" begin
    write(FOLDER / "config.md", """
        +++
        ignore = ["foo/"]
        +++
        """)
    write(FOLDER / "index.html", "<main>{{insertmd foo/bar.md}}</main>")
    mkpath(FOLDER / "foo")
    write(FOLDER / "foo" / "bar.md", """
        Some **md**.
        """)
    build(FOLDER)
    @test isfile(FOLDER / "__site" / "index.html")
    @test output_contains(FOLDER, "", "<main><p>Some <strong>md</strong>.</p>\n</main>")
end
