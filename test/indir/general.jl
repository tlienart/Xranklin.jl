include(joinpath(@__DIR__, "..", "utils.jl"))

@test_in_dir "_triggers" "i107" begin
    write(FOLDER / "counter", 0)
    write(FOLDER / "config.md", "")
    write(FOLDER / "index.md", """
        +++
        a = 555
        +++
        """)
    write(FOLDER / "abc.md", """
        +++
        fc = folderpath("counter")
        counter = read(fc, Int)
        write(fc, counter + 1)
        +++
        {{counter}}/{{fill a index.md}}
        """)

    # X.yprint("\n\n" * "="^50 * "\n\n")
    serve(FOLDER, single=true)
    @test output_contains(FOLDER, "abc", "0/555")
    @test read(FOLDER / "counter", Int) == 1

    # we change index.md but not the vars; foo must NOT triggered
    write(FOLDER / "index.md", """
        +++
        a = 555
        +++
        # Hello, abc
        """)
    X.yprint("\n\n" * "="^50 * "\n\n")
    serve(FOLDER, debug=true, single=true)

    @test output_contains(FOLDER, "abc", "0/555")
    @test read(FOLDER / "counter", Int) == 1
    @test output_contains(FOLDER, "", "Hello, abc")

    # # now let's change index.md but change the vars, foo MUST be triggered
    # # the global counter is at 1 because foo hasn't been executed so the 
    # # file counter has not been updated
    # write(FOLDER  / "index.md", """
    #     +++
    #     a = 777
    #     +++
    #     # Hello, bye
    #     """)
    # # X.yprint("\n\n" * "="^50 * "\n\n")
    # serve(FOLDER, single=true)
    # @test output_contains(FOLDER, "", "Hello, bye")
    # @test output_contains(FOLDER, "abc", "1/777")
    # @test read(FOLDER / "counter", Int) == 2

    # # X.yprint("\n\n" * "="^50 * "\n\n")
    # serve(FOLDER, single=true)
    # @test read(FOLDER / "counter", Int) == 2
end

@test_in_dir "_title_default" "i46" begin
    write(FOLDER / "config.md", "")
    write(FOLDER / "index.md", """
        # The Title

        title: {{title}}
        """)
    serve(FOLDER, single=true)
    @test output_contains(FOLDER, "", "title: The Title")
end
