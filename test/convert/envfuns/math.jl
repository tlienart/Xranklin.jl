include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "equation" begin
    s = raw"""
        \begin{equation}
            1 + 1 = 2
        \end{equation}
        """
    h = html(s)
    @test isapproxstr(h, """
        \\[
            1 + 1 = 2
        \\]
        """)

    s = raw"""
        \begin{equation*}
            1 + 1 = 2
        \end{equation*}
        """
    h = html(s)
    @test isapproxstr(h, """
        <div class="nonumber">\\[
            1 + 1 = 2
        \\]</div>
        """)
end

@testset "aligned" begin
    s = raw"""
        \begin{aligned}
            1 + 1 = 2
        \end{aligned}
        """
    h = html(s)
    @test isapproxstr(h, """
        \\[
            \\begin{aligned}
                1 + 1 = 2
            \\end{aligned}
        \\]
        """)

    s = raw"""
        \begin{aligned*}
            1 + 1 = 2
        \end{aligned*}
        """
    h = html(s)
    @test isapproxstr(h, """
        <div class="nonumber">\\[
            \\begin{aligned}
                1 + 1 = 2
            \\end{aligned}
        \\]</div>
        """)
end

@testset "align" begin
    s = raw"""
        \begin{align}
            1 + 1 = 2
        \end{align}
        """
    h = html(s)
    @test isapproxstr(h, """
        \\[
            \\begin{aligned}
                1 + 1 = 2
            \\end{aligned}
        \\]
        """)

    s = raw"""
        \begin{align*}
            1 + 1 = 2
        \end{align*}
        """
    h = html(s)
    @test isapproxstr(h, """
        <div class="nonumber">\\[
            \\begin{aligned}
                1 + 1 = 2
            \\end{aligned}
        \\]</div>
        """)
end
