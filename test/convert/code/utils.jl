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
    X.process_utils(utils, gc)
    @test X.valueglob(:_utils_mod_hash) == hash(utils)
    @test Set(X.valueglob(:_utils_hfun_names))  == Set([:foo, :bar])
    @test Set(X.valueglob(:_utils_lxfun_names)) == Set([:foo, :bar])
    @test X.valueglob(:_utils_var_names) == [:a,]

    lc = X.DefaultLocalContext(gc)
    s = "utils: {{a}}, lc:{{lang}}, gc:{{rss_file}}"
    h = html(s, lc)
    @test h // "<p>utils: 5, lc:julia, gc:feed</p>"
end
