include(joinpath(@__DIR__, "..", "utils.jl"))


@test_in_dir "_order" "i228" begin
    isfile(FOLDER/"config.md") && rm(FOLDER/"config.md")
    write(FOLDER/"config.jl", raw"""
        abc = 1//2
        def = "hello"
        lx"\newcommand{\foo}{**bar**}"
        lx"\newcommand{\foz}[1]{**#1**}"
        """)
    write(FOLDER/"index.md",raw"""
        A. {{abc}}
        B. {{def}}
        C. \foo
        D. \foz{aaa}
        """)
    build(FOLDER)

    for e in (
        "A. 1//2",
        "B. hello",
        "C. <strong>bar</strong>",
        "D. <strong>aaa</strong>"
        )
        @test output_contains(FOLDER, "", e) 
    end
end
