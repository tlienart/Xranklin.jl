@testset "math-a" begin
    let s = raw"""
        A $B$ C
        """
        h = html(s)
        l = latex(s)
        @test h // raw"<p>A \(B\) C</p>"
        @test l // raw"A $B$ C\par"
    end
end
