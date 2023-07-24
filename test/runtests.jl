using Test

@testset "everything" begin
@testset "misc" begin
    include("_0_misc.jl")
end
@testset "basics" begin
    include("_1_basics.jl")
end
@testset "indir" begin
    include("_2_indir.jl")
end
end
