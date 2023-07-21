include(joinpath(@__DIR__, "..", "utils.jl"))


@test_in_dir "_order" "i228" begin
    isfile(FOLDER/"config.md") && rm(FOLDER/"config.md")
    isfile(FOLDER/"utils.jl") && rm(FOLDER/"utils.jl")
    write(FOLDER/"config.jl", raw"""
        a = 5
        """)
    write(FOLDER/"index.md",raw"""
        {{a}}
        """)
    write(FOLDER/"err.md",raw"""
        {{b}}
        """)
    write(FOLDER/"errbad.md",raw"""
        A ``` B
        """)
    
    a = tempname()
    open(a, "w") do outf
        redirect_stderr(outf) do
            build(FOLDER)
        end
    end

    infos = read(a, String)

    for e in (
        "Info: Processed 3 pages.",
        "⚠ the following page(s) failed to be parsed properly:",
        "* errbad.md",
        "⚠ the following page(s) have blocks that couldn't be resolved:",
        "* err.md"
    )
        @test occursin(e, infos)
    end

end
#
