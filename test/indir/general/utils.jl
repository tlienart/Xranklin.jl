include(joinpath(@__DIR__, "..", "..", "utils.jl"))

# also testing reexports
@test_in_dir "_reexp" "rexp" begin
    dirset(FOLDER) # uses toy_example which sets a date with import
    write(FOLDER/"index.md", """
        {{thedate}}
        """)
    build(FOLDER)
    # this shows that the global variable is properly set
    # in config.md (which uses an import-style Dates.Date)
    # and then that it's correctly available here.
    test_contains(FOLDER, "", (
        "1947-09-19"
    ))
end

# explicit use of reexport in utils

@test_in_dir "_utils" "i239" begin
    dirset(FOLDER; scratch=true)
    write(FOLDER/"config.md","")
    write(FOLDER/"utils.jl","""
        @reexport using Dates

        foo(i) = Date(2023,2,10+i)
        """)

    for (i, case) in enumerate((
        # via explicit using in Utils
        """
        ```!
        Utils.foo(1)
        ```
        """,
        # via reexported import in *Core
        """
        ```!
        Dates.Date(2023,2,10+2)
        ```
        """,
        # via explicit using in Cell
        """
        ```!
        using Dates
        Date(2023,2,10+3)
        ```
        """,
        # via reexported using from utils.jl
        """
        ```!
        Date(2023,02,10+4)
        ```
        """,
        # in page var module it should also work
        """
        +++
        thedate = Date(2023,02,10+5)
        +++
        {{thedate}}
        """
    ))
        write(FOLDER/"index.md", case)
        build(FOLDER)
        test_contains(FOLDER, "", (
            "2023-02-$(10+i)"
        ))
    end
end

