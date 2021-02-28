# 1 - is the previous element a text block (T</p>) or not (B)
# 2 - is there a line skip before (LS)
# 3 - is the next element a text block (<p>T) or not (B)
# 4 - is there a line skip after (LS)

@testset "inline-0" begin
    # 0000
    @test html("`a`")     //
            "<p><code>a</code></p>"
    @test html("`a` `b`") //
            "<p><code>a</code> <code>b</code></p>"
end

@testset "inline-1" begin
    # 1000
    @test html("A `a`") //
            "<p>A <code>a</code></p>"
    @test html("A`a`")  //
            "<p>A<code>a</code></p>"
    # 0010
    @test html("`a`A") //
            "<p><code>a</code>A</p>"
    @test html("`a` A") //
            "<p><code>a</code> A</p>"

    # 0001
    @test html("`a`\n\n") // (
               "<p><code>a</code></p>")
    # 0001 + 0001 + 0000
    @test html("`a`\n\n`b`\n\n`c`") // (
               "<p><code>a</code></p>" *
               "<p><code>b</code></p>" *
               "<p><code>c</code></p>")

    # 0100
    @test html("\n\n`a`") //
               "<p><code>a</code></p>"
end

@testset "inline-2" begin
    # 1100
    @test html("A\n\n`a`") //
            "<p>A</p><p><code>a</code></p>"
    @test html("A B\n\n `a`") //
            "<p>A B</p><p><code>a</code></p>"
    # 0011
    @test html("`a`\n\nA") //
            "<p><code>a</code></p><p>A</p>"
    @test html("`a` `b` \n\n A") //
            "<p><code>a</code> <code>b</code></p><p>A</p>"
    # 1010
    @test html("A `a` `b` `c` B") //
            "<p>A <code>a</code> <code>b</code> <code>c</code> B</p>"
    # 0110
    @test html("\n\n`a`A") //
        "<p><code>a</code>A</p>"
    # 1001
    @test html("A `p`\n\n") //
        "<p>A <code>p</code></p>"
    # 0101
    @test html("\n\n`a`\n\n") //
            "<p><code>a</code></p>"
end

@testset "inline-3" begin
    # 1110
    @test html("A\n\n`a`B") //
            "<p>A</p><p><code>a</code>B</p>"
    # 1011
    @test html("A`a`\n\nB") //
            "<p>A<code>a</code></p><p>B</p>"
    # 0111
    @test html("\n\n`a`\n\nB") //
            "<p><code>a</code></p><p>B</p>"

    @test html("A\n\n`a`\n\n") //
            "<p>A</p><p><code>a</code></p>"
end

@testset "inline-4" begin
    # 1111
    @test html("A\n\n`a` `b`\n\nB") //
        "<p>A</p><p><code>a</code> <code>b</code></p><p>B</p>"
end
