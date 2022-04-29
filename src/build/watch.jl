"""
    TrackedFiles

Convenience type to keep track of files to watch.

Structure: {(root => file) => mtime} where `root` is the root of
the path, file is the filename with extension, and mtime is an
indication of when the file was last modified.
"""
const TrackedFiles = Dict{Pair{String, String}, Float64}


new_wf() = Dict{Symbol, TrackedFiles}(
    e => TrackedFiles()
    for e in (
        :other,
        :infra,
        :html,
        :md,
    )
)


"""
    update_files_to_watch!(wf, folder; in_loop)

Walk through `folder` and look for files to track sorting them by type.

* :md for all `.md` files that need to be watched excluding `config.md`
* :html for all `.html` files
* :infra for layout, libs, css files as well as `config.md` and `utils.jl`
* :other files for anything else (these files will just be copied over)
"""
function update_files_to_watch!(
            wf::Dict{Symbol, TrackedFiles},
            gc::GlobalContext,
            folder::String;
            in_loop::Bool=false
        )::Tuple{Dict{Symbol, TrackedFiles}, Bool}

    newpg    = false
    f2i, d2i = files_and_dirs_to_ignore(gc)

    # go over all files in the folder and add them to watched_files
    for (root, _, files) in walkdir(path(:folder))
        for file in files
            # assemble full path
            fpair = root => file
            fpath = joinpath(fpair...)
            fext  = splitext(file)[2]

            # early skip of irrelevant fpaths
            skip = !isfile(fpath) ||
                   startswith(fpath, path(:site)) ||
                   startswith(fpath, path(:pdf)) ||
                   startswith(fpath, path(:cache)) ||
                   startswith(fpath, path(:folder) / ".git") ||
                   should_ignore(gc, fpath, f2i, d2i)

            if skip
                rp = get_rpath(gc, fpath)
                if rp ∉ FRANKLIN_ENV[:skipped_files]
                    union!(FRANKLIN_ENV[:skipped_files], [rp])
                    startswith(fpath, path(:site)) || @debug """
                        🔺 skipping $(hl(str_fmt(rp), :cyan))
                        """
                end
                continue
            end

            if startswith(fpath, path(:css))    ||
               startswith(fpath, path(:layout)) ||
               startswith(fpath, path(:libs))   ||
               startswith(fpath, path(:rss))    ||
               file == "config.md"              ||
               file == "utils.jl"
                # files that, when they get changed, might change the aspect of
                # the full website
                add_if_new_file!(wf[:infra], fpair, in_loop)

            # if it's in assets, even with a .md or .html, just copy over
            elseif startswith(fpath, path(:assets))
                add_if_new_file!(wf[:other], fpair, in_loop)

            elseif fext == ".md"
                newpg |= add_if_new_file!(wf[:md], fpair, in_loop)


            elseif fext in (".html", ".htm")
                newpg |= add_if_new_file!(wf[:html], fpair, in_loop)

            else
                # any other files (e.g. Project.toml) just get copied over
                add_if_new_file!(wf[:other], fpair, in_loop)

            end
        end
    end
    return wf, newpg
end


"""
    find_files_to_watch(gc, folder)

Sets up a new dictionary of watched files and updates it with the function
`update_files_to_watch!`.
"""
function find_files_to_watch(
            gc::GlobalContext,
            folder::String
        )
    wf, _ = update_files_to_watch!(new_wf(), gc, folder)
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
            )::Bool
    # check if the file is already watched
    haskey(dict, fpair) && return false
    # if not, track it
    fpath = joinpath(fpair...)
    in_loop && @info """
        👀 tracking new file $(hl(str_fmt(get_rpath(fpath)), :cyan))
        """
    # save it's modification time, set to zero if it's a new file in a loop
    # to force its processing
    dict[fpair] = ifelse(in_loop, 0, mtime(fpath))
    return true
end


_access(p::String)   = p
_access(p::Regex)    = p.pattern
_isempty(p)          = isempty(_access(p))
_endswith(p, c)      = endswith(_access(p), c)
_check(f, p::Regex)  = match(p, f) !== nothing
_check(f, p::String) = (f == p)

"""
    files_and_dirs_to_ignore(gc)

Form the list of files to ignore and dirs to ignore. These lists have element
type `Union{String,Regex}` and so either indicate an exact match or a pattern.
"""
function files_and_dirs_to_ignore(gc::GlobalContext)
    SoR = StringOrRegex
    f2i = SoR[]  # files
    d2i = SoR[]  # dirs
    ignore = getvar(gc, :ignore_base, SoR[]) ∪ getvar(gc, :ignore, SoR[])
    for p in ignore
        (_isempty(p) || p == "/" || p == r"\/") && continue
        _endswith(p, '/') && push!(d2i, p)
        push!(f2i, p)
    end
    return f2i, d2i
end


"""
    should_ignore(gc, fpath, f2i, d2i)

Check if a file path should be ignored based on pre-computed `f2i` (files to
ignore) and `d2i` (directories to ignore). nore` global variable
from the current context. The `:ignore` variable can contain exact paths such
as `"README.md"` or indicators for directories such as `"node_modules/"` or
regex patterns for either like `r"READ*"` or `r"node_*/"`.
"""
function should_ignore(
            gc::GlobalContext,
            fpath::String,
            f2i,
            d2i
        )::Bool

    rpath = get_rpath(gc, fpath)
    return any(p -> startswith(rpath, p), d2i) ||   # dir match
           any(p -> _check(rpath, p), f2i)          # file match
end
