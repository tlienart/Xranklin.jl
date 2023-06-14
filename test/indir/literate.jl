include(joinpath(@__DIR__, "..", "utils.jl"))

@test_in_dir "_literate" "i144" begin
    write(FOLDER / "config.md", "")
    write(FOLDER / "Project.toml", """
        [deps]
        Literate = "98b081ad-f1c9-55d3-8b20-4c87d4299306"
        """)
    write(FOLDER / "utils.jl", """
        using Literate
        """
    )
    mkpath(FOLDER / "post")
    write(FOLDER / "post" / "Project.toml", """
        [deps]
        StableRNGs = "860ef19b-820b-49d6-a774-d7a799459cd3"
        """)
    write(FOLDER / "post" / "abc.jl", """
        # abc 

        using StableRNGs
        rand(StableRNG(0)) ≈ 0.19506488073747286

        # def

        using Pkg
        Pkg.project().path
        """
    )
    write(FOLDER / "index.md", raw"""
        \literate{post/abc.jl; project="."}
        """)
    write(FOLDER / "foo.md", """
        ```!
        using Pkg
        Pkg.project().path
        ```
        """)

    serve(FOLDER, single=true)
    @test output_contains(FOLDER, "", ">true</code>")
    @test output_contains(FOLDER, "", "post/Project.toml")
    @test output_contains(FOLDER, "foo", "Pkg")
    @test output_contains(FOLDER, "foo", "literate/Project.toml")
end

@test_in_dir "_compl" "complement to i144" begin
    write(FOLDER / "config.md", "")
    write(FOLDER / "Project.toml", """
        [deps]
        Literate = "98b081ad-f1c9-55d3-8b20-4c87d4299306"
        """)
    write(FOLDER / "utils.jl", """
        using Literate
        """)
    mkpath(FOLDER / "bar" / "baz")
    write(FOLDER / "bar" / "baz" / "Project.toml", """
        [deps]
        StableRNGs = "860ef19b-820b-49d6-a774-d7a799459cd3"
        """)
    write(FOLDER / "index.md", """
        ```!
        using Pkg
        Pkg.project().path
        ```
        """)
    write(FOLDER / "foo.md", raw"""
        \activate{bar/baz}
        ```!
        using Pkg
        Pkg.project().path
        ```
        """)
    serve(FOLDER, single=true)
    @test output_contains(FOLDER, "", "compl/Project.toml\"</code>")
    @test output_contains(FOLDER, "foo", "bar/baz/Project.toml\"</code>")
end
