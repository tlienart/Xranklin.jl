include(joinpath(@__DIR__, "..", "utils.jl"))

@testset "is_easily_serializable" begin
    # Acceptable
    @test X.is_easily_serializable(5)
    @test X.is_easily_serializable("hello")
    @test X.is_easily_serializable(true)
    @test X.is_easily_serializable([1,2,3])
    @test X.is_easily_serializable([1 2; 3 4])
    @test X.is_easily_serializable(1:5)
    @test X.is_easily_serializable(Dict(:a=>5, :b=>7))
    @test X.is_easily_serializable((1,2,3))
    @test X.is_easily_serializable(([1,2,3], 2, :abc))
    @test X.is_easily_serializable(today())
    @test X.is_easily_serializable(Dict(:a=>5, :b=>"hello"))
    @test X.is_easily_serializable(1:5)

    ld = LittleDict(:a=>0, :b=>1)
    @test X.is_easily_serializable(ld)
    ld2 = LittleDict(:a=>ld, :b=>ld)
    @test X.is_easily_serializable(ld2)

    d  = Dict(:a=>0,:b=>1)
    d2 = Dict(:a=>d,:c=>d)
    X.is_easily_serializable(d2)

    # Not acceptable
    @test !X.is_easily_serializable(x -> x)
    @test !X.is_easily_serializable(Module(:x))
    struct Foo
        a::Int
    end
    @test !X.is_easily_serializable(Foo(1))
    @test !X.is_easily_serializable([1, Foo(1)])
    @test !X.is_easily_serializable(Ptr{Int}())
    @test !X.is_easily_serializable(Ref(true))

end
