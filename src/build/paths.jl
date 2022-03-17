"""
    paths()

Retrieve the dictionary of paths.
"""
paths() = getgvar(:_paths)::LittleDict{Symbol, String}

"""
    path(s)

Return the path corresponding to `s` e.g. `path(:folder)`.
"""
path(s::Symbol)::String = get(paths(), s, "xxx")


function set_paths!(gc::GlobalContext, folder::String)
    @assert isdir(folder) "$folder is not a valid path"
    P = paths()
    f = P[:folder] = normpath(folder)
    P[:assets]     = f / "_assets"
    P[:css]        = f / "_css"
    P[:layout]     = f / "_layout"
    P[:libs]       = f / "_libs"
    P[:rss]        = f / "_rss"

    # output
    P[:site]  = f / "__site"
    P[:pdf]   = f / "__pdf"
    P[:cache] = f / "__cache"

    # keep track of prefix, see get_rpath, get_ropath
    setgvar!(:_idx_rpath,  lastindex(P[:folder] / "") + 1)
    setgvar!(:_idx_ropath, lastindex(P[:site] / "") + 1)
    return
end


"""
    get_rpath(fpath)

Extract the relative path out of the full path to a file.

## Example

    `/foo/bar/baz/site/blog/page.md` --> `blog/page.md`
"""
get_rpath(fpath::String) = fpath[(getgvar(:_idx_rpath)::Int):end]
get_rpath() = cur_lc().rpath
get_rdir()  = dirname(get_rpath())

"""
    get_ropath(opath)

Extract the relative path out of the full output path to a file.

## Example

    `/foo/bar/__site/baz/biz.md` --> `baz/biz.md`
"""
get_ropath(fpath::String) = fpath[(getgvar(:_idx_ropath)::Int):end]


"""
    get_opath(fpair, case)
    get_opath(fpath)

Given a file pair, form the output path (where the derived file will be
written/copied).
"""
function get_opath(fpair::Pair{String,String}, case::Symbol)::String
    base, file = fpair
    fpath      = joinpath(base, file)
    outbase    = form_output_base_path(base)

    # .md -> .html for md pages:
    case == :md && (file = change_ext(file))

    # file is index.html or 404.html or in keep_path --> keep the path
    # otherwise if file is page.md  --> .../page/index.html
    if case in (:md, :html)
        fname = noext(file)
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
function get_opath(fpath::String)::String
    d, f = splitdir(fpath)
    ext  = splitext(f)[2]
    case = ext == ".md" ? :md :
           ext == ".html" ? :html :
           :xx
    return get_opath(d => f, case)
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
       startswith(base, path(:libs))
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
    check_slug(lc, opath)

Check if the context defines a slug, if so move the file at `opath` to the
location corresponding to it.
If a file already exists at the slug path, a warning will be shown but the
file will be overwritten.

## Note

A slug is assumed to be in unix format (with forward slashes such as `a/b`).
Pre and post backslash are ignored. The path is appended to the `__site/`
folder. If a `.html` extension is given, that exact file path is written
otherwise it's ignored.

    * aa/bb.html --> __site/aa/bb.html
    * aa/bb/     --> __site/aa/bb/index.html
    * aa/bb      --> __site/aa/bb/index.html
    * /aa/bb/    --> __site/aa/bb/index.html

## Return

The possibly modified `opath`.

"""
function check_slug(lc::LocalContext, opath::String)::String
    isfile(opath) || return opath
    slug = getvar(lc, :slug, "")
    slug = strip(slug, '/')
    isempty(slug) && return opath

    if !endswith(slug, ".html")
        slug = splitext(slug)[1] / "index.html"
    end
    new_opath = path(:site) / slug
    mkpath(dirname(new_opath))

    # copy the file at the new location so it can be attained
    cp(opath, new_opath, force=true)
    return new_opath
end


"""
    unixify(rpath)

Take a path and return a unix version of the path (i.e. with forward slashes).
If `rpath` has an extension, the path is returned as is, otherwise the path
is returned with a final `/`.
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
unixify(s::SS) = unixify(string(s))


"""
    get_rurl(rpath)

Return the relative url corresponding to `rpath` for instance

* foo/bar/baz.md -> /foo/bar/baz/
"""
function get_rurl(rpath::String)
    rp = noext(rpath)
    rp = replace(rp, r"index$" => "")
    rp = unixify(rp)
    startswith(rp, '/') && return rp
    return "/$rp"
end
get_rurl(lc::LocalContext) = get_rurl(lc.rpath)
get_rurl() = get_rurl(cur_lc())
