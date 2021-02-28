@testset "inline-0" begin
    # 0000
    @test latex("`a`")     //
            raw"\texttt{a}"
    @test latex("`a` `b`") //
            raw"\texttt{a} \texttt{b}"
end

# -- XXX
# 
# @testset "inline-1" begin
#     # 100
#     @test latex("A `a`") //
#             raw"A \texttt{a}\par"
#     @test latex("A`a`")  //
#             raw"A\texttt{a}\par"
#     # 010
#     @test latex("`a`\n\n`b`") // "\\texttt{a}\n\n\\texttt{b}"
#     @test latex("`a`\n\n`b`\n\n`c`") // "\\texttt{a}\n\n\\texttt{b}\n\n\\texttt{c}"
#     # 001
#     @test latex("`a`A") // raw"\texttt{a}A\par"
#     @test latex("`a` A") // raw"\texttt{a} A\par"
#
#     @test latex("`a`\n\n") // "\\texttt{a}\n\n"
#     @test latex("\n\n`a`\n\n") // "\n\n\\texttt{a}\n\n"
# end
#
# @testset "inline-2" begin
#     # 110
#     @test latex("A\n\n`a`") // raw"A\par\texttt{a}\par"
#     @test latex("A B\n\n `a`") // raw"A B\par\texttt{a}\par"
#     # 0011
#     @test latex("`a`\n\nA") // raw"\texttt{a}\parA\par"
#     @test latex("`a` `b` \n\n A") // raw"\texttt{a} \texttt{b}\parA\par"
#     # 0110
#     @test latex("\n\n`a`A") // raw"\texttt{a}A\par"
#     # 1001
#     @test latex("A `a`\n\n`b`") // "A \\texttt{a}\\par\n\n\\texttt{b}"
#     # 1010
#     @test latex("A `a` `b` `c` B") // "A \\texttt{a} \\texttt{b} \\texttt{c} B\\par"
#     # 0101
#     @test latex("\n\n`a`\n\n") // "\n\n\\texttt{a}\n\n"
#     @test latex("\n\n`a` `b`\n\n") // "\n\n\\texttt{a} \\texttt{b}\n\n"
# end
#
# @testset "inline-3" begin
#     # 1110
#     @test latex("A\n\n`a`B") // "A\n\n\\texttt{a}B\\par"
#     # 0111
#     @test latex("\n\n`a`\n\nB") // "\n\n\\texttt{a}\n\nB\\par"
#     # 1101
#     @test latex("A\n\n`a`B") // "A\n\n\\texttt{a}B\\par"
#     # 1011
#     @test latex("A`a`\n\nB") // "A\\texttt{a}\n\nB\\par"
# end
#
# @testset "inline-4" begin
#     # 1111
#     @test latex("A\n\n`a` `b`\n\nB") // "A\n\n\\texttt{a} \\texttt{b}\n\nB\\par"
# end
