include("utils.jl")

@testset "anchors" begin
    include("context" / "anchors.jl")
    include("convert" / "hfuns" / "integrated.jl")
end

@testset "general" begin
    p = "indir"/"general"
    include(p/"general.jl")
    include(p/"hfuns.jl")
    include(p/"eval_order.jl")
    include(p/"config.jl")
    include(p/"utils.jl")
    include(p/"errors.jl")
end 

@testset "aux" begin
    p = "indir"/"auxfiles"
    include(p/"literate.jl")
    include(p/"rss.jl")
    include(p/"sitemap-robots.jl")
    include(p/"pagination.jl")
    include(p/"tags.jl")
end
