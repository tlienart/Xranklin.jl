include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@test_in_dir "_pagination" "i198" begin
    write(FOLDER / "config.md", "")
    write(FOLDER / "index.md", raw"""
        +++
        item_list = [
            "* item $i\n"
            for i in 1:20
        ]
        +++

        ABC

        {{paginate item_list 5}}

        DEF
        """)
    serve(FOLDER, single=true)
    @test output_contains(FOLDER, "", "<li>item 1</li>")
    @test output_contains(FOLDER, "", "<li>item 5</li>")
    @test !output_contains(FOLDER, "", "<li>item 6</li>")
    @test output_contains(FOLDER, "2", "<li>item 6</li>")
    @test output_contains(FOLDER, "2", "<li>item 10</li>")
    @test !output_contains(FOLDER, "2", "<li>item 11</li>")
    @test output_contains(FOLDER, "4", "<li>item 20</li>")
end
