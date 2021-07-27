include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "Utils" begin
    gc = X.DefaultGlobalContext()
    utils = """
        a = 5
        hfun_foo() = "bar"
        hfun_bar() = "bar"
        lx_foo() = "baz"
        lx_bar() = "baz"
        """
    X.process_utils(utils)
    @test X.valueglob(:_utils_mod_cntr) == 1
    @test X.valueglob(:_utils_mod_hash) == hash(utils)
    @test Set(X.valueglob(:_utils_hfun_names))  == Set([:foo, :bar])
    @test Set(X.valueglob(:_utils_lxfun_names)) == Set([:foo, :bar])
    @test X.valueglob(:_utils_var_names) == [:a,]

    lc = X.DefaultLocalContext(gc)
    s = "{{a}}"
    h = html(s, lc)
    @test h // "<p>5</p>"
end
