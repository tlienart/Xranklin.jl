include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "eval" begin
    mdl = Module()
    x   = 5
    code = """
        x = $x
        print(x)
        x^2
        """
    er = X.eval_nb_cell(mdl, code; cell_name="abc")
    @test er.success
    @test er.value == x^2
    @test er.out == "$x"
    @test er.err == ""

    # assignment (no cell name)
    code = """
        x = $x
        """
    er = X.eval_nb_cell(mdl, code)
    @test er.success
    @test er.value == 5
    @test er.out == ""
    @test er.err == ""

    # error
    code = """
        x = sqrt(-1)
        """
    nowarn()
    er = X.eval_nb_cell(mdl, code; cell_name="err")
    logall()
    @test !er.success
    @test isnothing(er.value)
    @test isempty(er.out)
    @test contains(er.err, "DomainError with -1.0:")    
end
