include("utils.jl")

include("integration_convert.jl")  # itest function

@testset "Misc" begin
    include("misc.jl")
end

@testset "Context" begin
    p = "context"
    include(p/"types.jl")
    include(p/"context.jl")
    include(p/"default_context.jl")
end

@testset "Context/Code" begin
    p = "context"/"code"
    include(p/"modules.jl")
    include(p/"notebook_vars.jl")
    include(p/"notebook_code.jl")
    include(p/"serialize.jl")
    include(p/"code-show.jl")
end

@testset "LaTeX" begin
    p = "convert/"
    include(p/"md_latex_newobj.jl")
    include(p/"md_latex_obj.jl")
end

@testset "MD2x" begin
    p = "convert/md2x"
    # rules
    include(p/"rules_text.jl")
    include(p/"rules_header.jl")
    include(p/"rules_maths.jl")
    include(p/"rules_def.jl")
    include(p/"rules_list.jl")
    include(p/"rules_table.jl")
    include(p/"rules_link.jl")
end

@testset "HFuns" begin
    p = "convert/hfuns"
    include(p/"evalstr.jl")
    include(p/"henv.jl")
end

@testset "EnvFuns" begin
    p = "convert/envfuns"
    include(p/"math.jl")
    include(p/"utils.jl")
end

@testset "LxFuns" begin
    p = "convert/lxfuns"
end

@testset "build" begin
    p = "build"
    include(p/"paths.jl")
    include(p/"watch.jl")
    include(p/"process.jl")
    include(p/"serve.jl")
end

# =========================================================

@testset "misc-utils" begin
    @testset "time_fmt" begin
        @test X.time_fmt(0.5)  == "(δt = 0.5s)"
        @test X.time_fmt(60)   == "(δt = 1.0min)"
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

@testset "bug fixes" begin
    include("bugs/latex.jl")
end

spurious_assets = dirname(dirname(pathof(Xranklin))) / "assets"
rm(spurious_assets, recursive=true, force=true)
