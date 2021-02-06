@testset "text" begin
    s = """
        A *B* _C_ **D**
        """ |> latex
    @test s // raw"A \textit{B} \textit{C} \textbf{D}\par"
end
