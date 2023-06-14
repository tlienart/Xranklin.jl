include(joinpath(@__DIR__, "..", "..", "utils.jl"))

@testset "split arg" begin
    s = """ :a, 5 """
    a, kw = X._lx_split_args_kwargs(s)
    @test a == (:a, 5)
    @test kw == (;)

    s = """ b=5, c=7 """
    a, kw = X._lx_split_args_kwargs(s)
    @test a == ()
    @test kw == (; b=5, c=7)

    s = """ :a, 5; foo="hello", bar=true """
    a, kw = X._lx_split_args_kwargs(s)
    @test a == (:a, 5)
    @test kw == (; foo="hello", bar=true)

    # seems happy to figure out args in the wrong order, not ideal but ok
    s = """ foo="bar", 5 """
    a, kw = X._lx_split_args_kwargs(s)
    @test a == (5,)
    @test kw == (;foo="bar")

    s = """ foo, bar """
    a, kw = X._lx_split_args_kwargs(s)
    @test isempty(a) && isempty(kw)
end
