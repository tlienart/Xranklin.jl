"""
    TrackedFiles

Convenience type to keep track of files to watch.

Structure: {(root => file) => mtime} where `root` is the root of
the path, file is the filename with extension, and mtime is an
indication of when the file was last modified.
"""
const TrackedFiles = LittleDict{Pair{String, String}, Float64}




"""
    collect_files_to_watch(folder)

Walk through `folder` and look for files to track,
"""
function collect_files_to_watch(folder)::NamedTuple
    set_paths(folder)


    to_ignore = globvar(:ignore_base) ∪ globvar(:ignore)
    dir_to_ignore = Union{String,Regex}[]
    files_to_ignore
    filter!(!_isempty, to_ignore)
    # patterns for directories
    dir_mask = [_endswith(c, '/') for c in to_ignore]
    # ignore '/' or other single char
    d2i = filter!(d -> length(d) >  1, to_ignore[dir_mask])
    f2i = to_ignore[.!dir_mask]



    watched_files = LittleDict{Symbol, TrackedFiles}(
        e => TrackedFiles()
        for e in (:other, :infra, :md, :html, :literate)
    )

    # go over all files in the folder and add them to watched_files
    for (root, _, files) in walkdir(path(:folder))
        for file in files
            # assemble full path
            fpair = root => file
            fpath = fpair.first / fpair.second
            fext  = splitext(file)[2]

            # early skip of irrelevant fpaths
            (!isfile(fpath) || should_ignore(fpath)) && continue


        end
    end

    return watched_files
end


_access(p::String)   = p
_access(p::Regex)    = p.pattern
_isempty(p)          = isempty(_access(p))
_endswith(p, c)      = endswith(_access(p), c)
_check(f, p::Regex)  = match(p, f) !== nothing
_check(f, p::String) = (f == p)

"""
    files_and_dirs_to_ignore()

Form the list of files to ignore and dirs to ignore. These lists have element
type `Union{String,Regex}` and so either indicate an exact match or a pattern.
"""
function files_and_dirs_to_ignore()
    ignore = globvar(:ignore_base) ∪ globvar(:ignore)
    f2i    = StringOrRegex[]
    d2i    = StringOrRegex[]
    for p in ignore
        (_isempty(p) || p == "/" || p == r"\/") && continue
        _endswith(p, '/') && push!(d2i, p)
        push!(f2i, p)
    end
    return f2i, d2i
end

"""
    should_ignore(fpath, f2i, d2i)

Check if a file path should be ignored based on pre-computed `f2i` (files to
ignore) and `d2i` (directories to ignore). nore` global variable
from the current context. The `:ignore` variable can contain exact paths such
as `"README.md"` or indicators for directories such as `"node_modules/"` or
regex patterns for either like `r"READ*"` or `r"node_*/"`.
"""
function should_ignore(fpath::String, f2i, d2i)
    # form path relative to folder
    rpath = fpath[env(:idx_rpath):end]
    return any(p -> startswith(rpath, p), d2i) ||   # dir match
           any(p -> _check(rpath, p), f2i)          # file match
end
