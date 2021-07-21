(/)(s...) = joinpath(s...)

"""
    path(s)

Return the path corresponding to `s` e.g. `path(:folder)`.
"""
path(s::Symbol) = env(:paths)[s]


function set_paths(folder::String=pwd())
    @assert isdir(folder) "$folder is not a valid path"
    setenv(:idx_rpath, lastindex(folder / "") + 1)
    P = env(:paths)
    f = P[:folder] = normpath(folder)
    P[:site]       = f / "__site"
    P[:assets]     = f / "_assets"
    P[:css]        = f / "_css"
    P[:layout]     = f / "_layout"
    P[:libs]       = f / "_libs"
    P[:rss]        = f / "_rss"          # optional/generated
    P[:literate]   = f / "_literate"     # optional
    P[:code_out]   = ""
    return
end


"""
    code_output_path(s="")

Return the output_path associated with a code block.
This makes it easy to have a code block that saves something to file
and then later have something that loads that file e.g.:

* in the code block: `savefig(output_path("f1.png"))`
* in the markdown: `\fig{"f1.png"}`
"""
code_output_path(s::String="") = path(:code_out) / s
