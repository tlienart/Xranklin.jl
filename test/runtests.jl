using Xranklin, LiveServer, Test; X = Xranklin;

X.FRANKLIN_ENV[:STRICT_PARSING] = false
X.FRANKLIN_ENV[:SHOW_WARNINGS]  = false

include("utils.jl")

include("integration_convert.jl")  # itest function

@testset "Context" begin
    p = "context/"
    include("$p/types.jl")
    include("$p/context.jl")
    include("$p/default_context.jl")
end

@testset "LaTeX" begin
    p = "convert/"
    include("$p/md_latex_newobj.jl")
    include("$p/md_latex_obj.jl")
end

@testset "MD2x" begin
    p = "convert/md2x"
    include("$p/resolve_inline.jl")
    # rules
    include("$p/rules_text.jl")
    include("$p/rules_headers.jl")
    include("$p/rules_maths.jl")
    include("$p/rules_vars.jl")
end

#=
TODO: need more tests for vars:

* with errors

Need to add tests for some utils as well
=#

@testset "build" begin
    include("build/paths.jl")
end
