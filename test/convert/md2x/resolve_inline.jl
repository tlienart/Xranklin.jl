# 1 - is the previous element a text block (T</p>) or not (B)
# 2 - is there a line skip before (LS)
# 3 - is the next element a text block (<p>T) or not (B)
# 4 - is there a line skip after (LS)
#
# 0000 -> B _ B
# 1000 -> T</p> _ B
#
# in LaTeX setting the 3d one is always true, so in the tests
# below we pair tests with the 3d bit 0/1
#
# etc.

# =====
# 0 - 1
# =====

@testset "0000/0010" begin
    let s = "`a`"
        @test html(s) //
                "<p><code>a</code></p>"
        @test latex(s) //
                raw"\texttt{a}"
    end
    let s = "`a` `b`"
        @test html(s) //
                "<p><code>a</code> <code>b</code></p>"
        @test latex(s) //
                raw"\texttt{a} \texttt{b}"
    end
    let s = "`a`A"
        @test html(s) //
                "<p><code>a</code>A</p>"
        @test latex(s) //
                raw"\texttt{a}A\par"
    end
    let s = "`a` A"
        @test html(s) //
            "<p><code>a</code> A</p>"
        @test latex(s) //
            raw"\texttt{a} A\par"
    end
end

# =====
# 1 - 2
# =====

@testset "1000/1010" begin
    let s = "A`a`"
        @test html(s) //
                "<p>A<code>a</code></p>"
        @test latex(s) //
                raw"A\texttt{a}"
    end
    let s = "A `a`"
        @test html(s) //
                "<p>A <code>a</code></p>"
        @test latex(s) //
                raw"A \texttt{a}"
    end
    let s = "A `a` A"
        @test html(s) //
            "<p>A <code>a</code> A</p>"
        @test latex(s) //
            raw"A \texttt{a} A\par"
    end
    let s = "A `a` `b` `c` B"
        @test html(s) //
            "<p>A <code>a</code> <code>b</code> <code>c</code> B</p>"
        @test latex(s) //
            raw"A \texttt{a} \texttt{b} \texttt{c} B\par"
    end
end

@testset "0001/0011" begin
    let s = "`a`\n\n"
        @test html(s) //
            "<p><code>a</code></p>"
        @test latex(s) //
            raw"\texttt{a}\par"
    end
    let s = "`a`\n\n`b`\n\n`c`"
        @test html(s) // (
                "<p><code>a</code></p>" *
                "<p><code>b</code></p>" *
                "<p><code>c</code></p>")
        @test latex(s) //
                raw"""
                \texttt{a}\par

                \texttt{b}\par

                \texttt{c}"""
    end
    let s = "`a`\n\nA"
        @test html(s) //
            "<p><code>a</code></p><p>A</p>"
        @test latex(s) //
            raw"""
            \texttt{a}\par
            A\par"""
    end
    let s = "`a` `b` \n\n A"
        @test html(s) //
            "<p><code>a</code> <code>b</code></p><p>A</p>"
        @test latex(s) //
            raw"""
            \texttt{a} \texttt{b}\par
            A\par"""
    end
end

@testset "0100/0110" begin
    let s = "\n\n`a`"
        @test html(s) //
               "<p><code>a</code></p>"
        @test latex(s) //
               raw"\texttt{a}"
    end
    let s = "\n\n`a`A"
        @test html(s) //
            "<p><code>a</code>A</p>"
        @test latex(s) //
            raw"\texttt{a}A\par"
    end
end

# =====
# 2 - 3
# =====

@testset "1100/1110" begin
    let s = "A\n\n`a`"
        @test html(s) //
            "<p>A</p><p><code>a</code></p>"
        @test latex(s) //
            raw"""
            A\par
            \texttt{a}"""
    end
    let s = "A B\n\n `a`"
        @test html(s) //
            "<p>A B</p><p><code>a</code></p>"
        @test latex(s) //
            raw"""
            A B\par
            \texttt{a}"""
    end
    let s = "A\n\n`a`B"
        @test html(s) //
                "<p>A</p><p><code>a</code>B</p>"
        @test latex(s) //
                raw"""
                A\par
                \texttt{a}B\par"""
    end
end

@testset "1001/1011" begin
    let s = "A `p`\n\n"
        @test html(s) //
            "<p>A <code>p</code></p>"
        @test latex(s) //
            raw"A \texttt{p}\par"
    end
    let s = "A`a`\n\nB"
        @test html(s) //
                "<p>A<code>a</code></p><p>B</p>"
        @test latex(s) //
                raw"""
                A\texttt{a}\par
                B\par"""
    end
end

@testset "0101/0111" begin
    let s = "\n\n`a`\n\n"
        @test html(s) //
                "<p><code>a</code></p>"
        @test latex(s) //
                raw"\texttt{a}\par"
    end
    let s = "\n\n`a`\n\nB"
        @test html(s) //
                "<p><code>a</code></p><p>B</p>"
        @test latex(s) //
            raw"""
            \texttt{a}\par
            B\par"""
    end
end

# =====
# 3 - 4
# =====
@testset "1101/1111" begin
    let s = "A\n\n`a`\n\n"
        @test html(s) //
            "<p>A</p><p><code>a</code></p>"
        @test latex(s) //
            raw"""
            A\par
            \texttt{a}\par"""
    end
    let s = "A\n\n`a` `b`\n\nB"
        @test html(s) //
            "<p>A</p><p><code>a</code> <code>b</code></p><p>B</p>"
        @test latex(s) //
            raw"""
            A\par
            \texttt{a} \texttt{b}\par
            B\par
            """
    end
end
