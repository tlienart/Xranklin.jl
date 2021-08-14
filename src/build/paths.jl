(/)(s...) = joinpath(s...)

"""
    paths()

Retrieve the dictionary of paths.
"""
paths() = getgvar(:_paths)::LittleDict{Symbol, String}

"""
    path(s)

Return the path corresponding to `s` e.g. `path(:folder)`.
"""
path(s::Symbol)::String = get(paths(), s, "")


function set_paths!(gc::GlobalContext, folder::String)
    @assert isdir(folder) "$folder is not a valid path"
    P = paths()
    f = P[:folder] = normpath(folder)
    P[:assets]     = f / "_assets"
    P[:css]        = f / "_css"
    P[:layout]     = f / "_layout"
    P[:libs]       = f / "_libs"
    P[:rss]        = f / "_rss"          # optional/generated
    P[:literate]   = f / "_literate"     # optional

    # output
    P[:site]  = f / "__site"
    P[:pdf]   = f / "__pdf"
    P[:cache] = f / "__cache"

    P[:code_out]   = ""

    # keep track of prefix, see get_rpath, get_ropath
    setgvar!(:_idx_rpath,  lastindex(P[:folder] / "") + 1)
    setgvar!(:_idx_ropath, lastindex(P[:site] / "") + 1)
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
get_rpath(fpath::String) = fpath[(getgvar(:_idx_rpath)::Int):end]


"""
    get_ropath(opath)

Extract the relative path out of the full output path to a file.
"""
get_ropath(fpath::String) = fpath[(getgvar(:_idx_ropath)::Int):end]


"""
    form_output_path

Given a file pair, form the output path (where the derived file will be
written/copied).
"""
function form_output_path(fpair::Pair{String,String}, case::Symbol)::String
    base, file = fpair
    fpath      = joinpath(base, file)
    outbase    = form_output_base_path(base)

    # .md -> .html for md pages:
    case == :md && (file = change_ext(file))

    # file is index.html or 404.html or in keep_path --> keep the path
    # otherwise if file is page.md  --> .../page/index.html
    if case in (:md, :html)
        fname = splitext(file)[1]
        skip = fname ∈ ("index", "404") ||
               endswith(fname, "/index") ||
               keep_path(fpath)
        skip || (file = fname / "index.html")
    end
    outpath = outbase / file
    outdir  = splitdir(outpath)[1]
    isdir(outdir) || mkpath(outdir)
    return outpath
end

"""
    form_output_base_path(base)

Form the base output path depending on `base` stripping away `_` for special
folders like `_css` or `_libs`.
"""
function form_output_base_path(base::String)::String
    if startswith(base, path(:assets)) ||
       startswith(base, path(:css))    ||
       startswith(base, path(:layout)) ||
       startswith(base, path(:libs))   ||
       startswith(base, path(:literate))
       # for special folders, strip away the preceding `_`
       return path(:site) / lstrip(get_rpath(base), '_')
   end
   return outpath = path(:site) / get_rpath(base)
end


"""
    keep_path(fpath)

Check a file path against the global variable `:keep_path` to see
if either there's an exact match (including extension) or whether
it's a dir indicator and fpath starts with it.
"""
function keep_path(fpath::String)
    keep = getgvar(:keep_path)::Vector{String}
    isempty(keep) && return false
    rpath = get_rpath(fpath)
    # check if either we have an exact match blog/page.md == blog/page.md
    # or if it's a dir and the starts match blog/page.md <> blog/
    for k in keep
        k == rpath && return true
        endswith(k, '/') && startswith(rpath, k) && return true
    end
    return false
end


"""
    unixify(rpath)

Take a path and return a unix version of the path (i.e. with forward slashes).
For instance to convert a relative path corresponding to a local file and
convert it to a relative URL.
"""
function unixify(rpath::String)
    isempty(rpath) && return "/"
    Sys.isunix() || (rpath = replace(rpath, "\\" => "/"))
    # if it has an extension, return as is
    isempty(splitext(rpath)[2]) || return rpath
    # if it doesn't have an extension, check if it ends with `/` e.g.: `/blah/`
    # if it doesn't, add one and return
    endswith(rpath, '/') || return rpath * "/"
    return rpath
end
