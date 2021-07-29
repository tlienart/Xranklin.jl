using Xranklin
using LiveServer
using Logging
using Test
X = Xranklin;

X.setenv(:strict_parsing, false)

include("utils.jl")

include("integration_convert.jl")  # itest function

@testset "Context" begin
    p = "context"
    include(p/"types.jl")
    include(p/"context.jl")
    include(p/"default_context.jl")
end

@testset "LaTeX" begin
    p = "convert/"
    include(p/"md_latex_newobj.jl")
    include(p/"md_latex_obj.jl")
end

@testset "MD2x" begin
    p = "convert/md2x"
    include(p/"resolve_inline.jl")
    # rules
    include(p/"rules_text.jl")
    include(p/"rules_headers.jl")
    include(p/"rules_maths.jl")
    include(p/"rules_defs.jl")
end

@testset "Code" begin
    p = "convert/code"
    include(p/"modules.jl")
    include(p/"run.jl")
    include(p/"utils.jl")
end

@testset "build" begin
    include("build/paths.jl")
    include("build/watch.jl")
    include("build/process.jl")
    include("build/serve.jl")
end

# =========================================================

@testset "misc-utils" begin
    @testset "time_fmt" begin
        @test X.time_fmt(0.5) == "(δt = 0.5s)"
        @test X.time_fmt(60) == "(δt = 1.0min)"
        @test X.time_fmt(0.01) == "(δt = 10ms)"
    end
    @testset "str_fmt" begin
        @test X.str_fmt("hello") == "hello"
        @test X.str_fmt("hello", 3) == "[...]llo"
    end
    @testset "change_ext" begin
        @test X.change_ext("foo.html", ".md") == "foo.md"
        @test X.change_ext("foo.md") == "foo.html"
    end
end
