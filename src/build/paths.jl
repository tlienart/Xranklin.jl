(/)(s...) = joinpath(s...)

"""
    path(s)

Return the path corresponding to `s` e.g. `path(:folder)`.
"""
path(s::Symbol) = env(:PATHS)[s]


function set_paths(folder::String)
    @assert isdir(folder) "$folder is not a valid path"
    P = env(:PATHS)
    f = P[:folder] = normpath(folder)
    P[:site]       = f / "__site"
    P[:assets]     = f / "_assets"
    P[:css]        = f / "_css"
    P[:layout]     = f / "_layout"
    P[:libs]       = f / "_libs"
    P[:rss]        = f / "_rss"          # optional/generated
    P[:literate]   = f / "_literate"     # optional
    return
end
