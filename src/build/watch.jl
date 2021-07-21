"""
    TrackedFiles

Convenience type to keep track of files to watch.

Structure: {(root => file) => mtime} where `root` is the root of
the path, file is the filename with extension, and mtime is an
indication of when the file was last modified.
"""
const TrackedFiles = LittleDict{Pair{String, String}, Float64}




"""
    find_files_to_watch(folder)

Walk through `folder` and look for files to track,
"""
function find_files_to_watch(
            folder::String,
            in_loop::Bool = false
            )::LittleDict{Symbol, TrackedFiles}

    set_paths(folder)
    f2i, d2i = files_and_dirs_to_ignore()

    wf = LittleDict{Symbol, TrackedFiles}(
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
            skip = !isfile(fpath) ||
                   startswith(fpath, path(:site)) ||
                   startswith(fpath, path(:folder) / ".git") ||
                   should_ignore(fpath, f2i, d2i)
            if skip
                debug(LOGGER, "Skipping $fpath")
                continue
            end

            if startswith(fpath, path(:css)) ||
                   startswith(fpath, path(:layout)) ||
                   startswith(fpath, path(:libs)) ||
                   file == "config.md" || file == "utils.jl"
                # files that, when they get changed, might change the aspect of
                # the full website
                add_if_new_file!(wf[:infra], fpair, in_loop)

            elseif startswith(fpath, path(:assets))
                add_if_new_file!(wf[:other], fpair, in_loop)

            elseif startswith(fpath, path(:literate))
                add_if_new_file!(wf[:literate], fpair, in_loop)

            elseif fext == ".md"
                add_if_new_file!(wf[:md], fpair, in_loop)

            elseif fext in (".html", ".htm")
                add_if_new_file!(wf[:html], fpair, in_loop)

            else
                # any other files (e.g. Project.toml) just get copied over
                add_if_new_file!(wf[:other], fpair, in_loop)

            end
        end
    end
    return wf
end


"""
    add_if_new_file!(d, fpair, in_loop)

Helper function, if `fpair` is not referenced in the dictionary (new file) add
the entry to the dictionary with the time of last modification.
"""
function add_if_new_file!(
            dict::TrackedFiles,
            fpair::Pair{String, String},
            in_loop::Bool=false
            )::Nothing
    # check if the file is already watched
    haskey(dict, fpair) && return nothing
    # if not, track it
    fpath = joinpath(fpair...)
    # save it's modification time, set to zero if it's a new file in a loop
    # to force its processing
    dict[fpair] = ifelse(in_loop, 0, mtime(fpath))
    return nothing
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
