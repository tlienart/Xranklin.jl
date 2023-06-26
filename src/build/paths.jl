"""
    paths(gc)

Retrieve the dictionary of paths.
"""
paths(gc::GlobalContext) = gc.vars[:_paths]::Dict{Symbol, String}

"""
    path(gc, s)

Return the path corresponding to `s` e.g. `path(:folder)`.
"""
path(gc::GlobalContext, s::Symbol)::String = get(paths(gc), s, "")
path(lc::LocalContext, s::Symbol)::String  = path(lc.glob, s)
path(s::Symbol) = path(cur_gc(), s)


function set_paths!(gc::GlobalContext, folder::String)
    @assert isdir(folder) "$folder is not a valid path"
    P = paths(gc)
    f = P[:folder] = normpath(folder)
    P[:assets]     = f / env(:assets_folder)
    P[:css]        = f / env(:css_folder)
    P[:layout]     = f / env(:layout_folder)
    P[:libs]       = f / env(:libs_folder)
    P[:rss]        = f / env(:rss_folder)

    # output
    P[:site]  = f / env(:output_site_folder)
    P[:pdf]   = f / env(:output_pdf_folder)
    P[:cache] = f / env(:output_cache_folder)

    # keep track of prefix, see get_rpath, get_ropath
    setvar!(gc, :_idx_rpath,  lastindex(P[:folder] / "") + 1)
    setvar!(gc, :_idx_ropath, lastindex(P[:site] / "") + 1)
    return
end


"""
    get_rpath(gc, fpath)

Extract the relative path out of the full path to a file.

## Example

    `/foo/bar/baz/site_folder/blog/page.md` --> `blog/page.md`
"""
get_rpath(gc::GlobalContext, fpath::String) =
    fpath[(getvar(gc, :_idx_rpath, 1)::Int):end]

"""
    exists_rpath(gc, rpath)

Check if a relative path `rpath` corresponds to an actual file.
"""
exists_rpath(gc::GlobalContext, rpath::String) =
    isfile(paths(gc)[:folder] / rpath)

"""
    get_ropath(gc, opath)

Extract the relative path out of the full output path to a file.

## Example

    `/foo/bar/__site/baz/biz.md` --> `baz/biz.md`
"""
get_ropath(gc::GlobalContext, fpath::String) =
    fpath[(getvar(gc, :_idx_ropath, 1)::Int):end]


"""
    get_opath(gc, fpair, case)
    get_opath(gc, fpath)

Given a file pair, form the output path (where the derived file will be
written/copied).
"""
function get_opath(
            gc::GlobalContext,
            fpair::Pair{String,String},
            case::Symbol
        )::String

    base, file = fpair
    fpath      = joinpath(base, file)
    outbase    = form_output_base_path(gc, base)

    # .md -> .html for md pages:
    case == :md && (file = change_ext(file))

    # file is index.html or 404.html or in keep_path --> keep the path
    # otherwise if file is page.md  --> .../page/index.html
    if case in (:md, :html)
        fname = noext(file)
        skip = fname ∈ ("index", "404") ||
               endswith(fname, "/index") ||
               keep_path(gc, fpath)
        skip || (file = fname / "index.html")
    end
    outpath = outbase / file
    outdir  = splitdir(outpath)[1]
    isdir(outdir) || mkpath(outdir)
    return outpath
end
function get_opath(
            gc::GlobalContext,
            fpath::String
        )::String

    d, f = splitdir(fpath)
    ext  = splitext(f)[2]
    case = ext == ".md" ? :md :
           ext == ".html" ? :html :
           :xx
    return get_opath(gc, d => f, case)
end


"""
    form_output_base_path(gc, base)

Form the base output path depending on `base` stripping away `_` for special
folders like `_css` or `_libs`.
"""
function form_output_base_path(
            gc::GlobalContext,
            base::String
        )::String

    if startswith(base, path(gc, :assets)) ||
       startswith(base, path(gc, :css))    ||
       startswith(base, path(gc, :layout)) ||
       startswith(base, path(gc, :libs))
       # for special folders, strip away the preceding `_`
       return path(gc, :site) / lstrip(get_rpath(gc, base), '_')
   end
   return path(gc, :site) / get_rpath(gc, base)
end


"""
    keep_path(gc, fpath)

Check a file path against the global variable `:keep_path` to see
if either there's an exact match (including extension) or whether
it's a dir indicator and fpath starts with it.
"""
function keep_path(
            gc::GlobalContext,
            f_or_rpath::String
        )::Bool

    keep = union(
        getvar(gc, :keep_path, String[]),
        ["404.html"]
    )
    if f_or_rpath in keys(gc.children_contexts)
        rpath = f_or_rpath
    else
        rpath = get_rpath(gc, f_or_rpath)
    end
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
        slug = noext(slug)slug / "index.html"
    end
    new_opath = path(lc, :site) / slug
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
    return "/$(lstrip(rp, '/'))"
end


"""
    get_full_url(rpath)

Construct the full url under the assumption that `:website_url` has been set.
"""
function get_full_url(gc::GlobalContext, rpath::String)
    website_url = getvar(gc, :website_url, "")
    #
    # keep_path case
    #
    if keep_path(gc, rpath)
        return website_url * normalize_uri(lstrip(unixify(rpath), '/'))
    end
    #
    # basic case
    #
    return website_url * normalize_uri(lstrip(get_rurl(rpath), '/') * "index.html")
end
