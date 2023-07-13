include(joinpath(@__DIR__, "..", "..", "utils.jl"))

# these tests are superseded by other more advanced tests, just kept for
# helping with any digging in that there may be to do when changing stuff.

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
end
