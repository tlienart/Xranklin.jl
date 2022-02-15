include("utils.jl")

@testset "string_to_anchor" begin
    s = "abc"
    @test X.string_to_anchor(s) // s

    s = " ^foo^"
    @test X.string_to_anchor(s) == "foo"
    @test X.string_to_anchor(s, keep_first_caret=true) == "^foo"
end

# @testset "BiDict" begin
#     bd = BiDict{Symbol,String}()
#     push!(bd, :a, "b")
#     @test bd.fwd[:a] == "b"
#     @test bd.bwd["b"] == :a
# end

@testset "filehash" begin
    fp = tempname()
    write(fp, "hello")
    @test Xranklin.filehash(fp) == 0x9a71bb4c
    fp2 = tempname()
    write(fp2, "hello")
    @test Xranklin.filehash(fp2) == Xranklin.filehash(fp)
    fp3 = tempname()
    write(fp3, "bye")
    @test Xranklin.filehash(fp3) != Xranklin.filehash(fp2)
end

@testset "depsmap" begin
    d, _ = testdir()
    dm   = X.DepsMap()

    p1 = tempname(d); write(p1, "pg1.md")
    p2 = tempname(d); write(p2, "pg2.md")
    l1 = tempname(d); write(l1, "l1.jl")
    l2 = tempname(d); write(l2, "l2.jl")

    push!(dm, p1, l1)
    push!(dm, p1, l2)
    push!(dm, p2, l2)

    @test p1 in dm.fwd_keys
    @test p2 in dm.fwd_keys
    @test l1 in dm.bwd_keys
    @test l2 in dm.bwd_keys
    @test l1 in keys(dm.hashes)

    @test dm.fwd[p1] == Set([l1, l2])
    @test dm.bwd[l1] == Set([p1])
    @test dm.bwd[l2] == Set([p1, p2])

    delete!(dm, p1)
    @test p1 ∉ dm.fwd_keys
    @test p1 ∉ keys(dm.fwd)
    @test l1 ∉ keys(dm.bwd)
    @test l1 ∉ dm.bwd_keys
    @test dm.bwd[l2] == Set([p2])
    @test l1 ∉ keys(dm.hashes)
end