(/)(s...) = joinpath(s...)

"""
    path(s)

Return the path corresponding to `s` e.g. `path(:folder)`.
"""
path(s::Symbol) = env(:paths)[s]


function set_paths(folder::String=pwd())
    @assert isdir(folder) "$folder is not a valid path"
    # keep track of prefix, see get_rpath
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


"""
    get_rpath(fpath)

Extract the relative path out of the full path to a file.

## Example

    `/foo/bar/baz/site/blog/page.md` --> `blog/page.md`
"""
get_rpath(fpath::String) = fpath[env(:idx_rpath):end]
