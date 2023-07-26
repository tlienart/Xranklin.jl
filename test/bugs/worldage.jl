include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "utils" begin
    u = """
        foo() = get_page_tags()
        """
    lcu = lc_with_utils(u)
    begin # precomp
        (X.utils_module(lcu)).foo()
    end
    @time begin
        f = getproperty(X.utils_module(lcu), :foo)
        @test Base.@invokelatest f() == Dict{String,String}()
    end
    @time begin
        @test (X.utils_module(lcu)).foo() == Dict{String,String}()
    end
    @time begin
        @test X.outputof(:foo, String[], lcu; internal=false) == "Dict{String, String}()"
    end
end

@testset "utils2" begin
    u = """
        hfun_foo() = :bar
        """
    lcu = lc_with_utils(u)
    @time begin
        @test X.outputof(:hfun_foo, String[], lcu; internal=false) == "bar"
    end
end
