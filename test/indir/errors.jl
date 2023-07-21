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
        This is before the error, yada yada, it's all **fine**! and then
        it's maybe much later that there are issues... 

        ABCDEFGHIJKLMNOPQRSTUVWXYZ

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

    @test output_contains(FOLDER, "errbad", """
        <p>This is before the error, yada yada, it's all <strong>fine</strong>! and then
        it's maybe much later that there are issues... </p>
        <p>ABCDEFGHIJ</p>
        <span style="color:red">... truncated content, a parsing error occurred at some point after this ...</span>
        """)
end
#
