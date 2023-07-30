include(joinpath(@__DIR__, "..", "utils.jl"))

#
# Making sure that cur_lc always refers to the correct path
#

@testset "order getvar/getvarfrom" begin
    gc = X.DefaultGlobalContext()
    l1 = X.DefaultLocalContext(gc; rpath="l1")
    l2 = X.DefaultLocalContext(gc; rpath="l2")

    s2 = """
        ```!
        # hideall
        setlvar!(:a2, 10)
        ```
        """
    h2 = html(s2, l2)
    @test h2 == ""

    s1 = """
        ```!
        # hideall
        setlvar!(:a1, 5)
        ```

        ```!
        getlvar(:a1)^2
        ```

        ```!
        getvarfrom(:a2, "l2")
        ```

        ```!
        getlvar(:a1)/2
        ```
        """
    h1 = html(s1, l1)

    for e in (
        "25", "10", "2.5"
    )
        @test occursin(e, h1)
    end
end
