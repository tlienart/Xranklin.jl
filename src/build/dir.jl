"""
    TrackedFiles

Convenience type to keep track of files to watch.

Structure: {(root => file) => mtime} where `root` is the root of
the path, file is the filename with extension, and mtime is an
indication of when the file was last modified.
"""
const TrackedFiles = LittleDict{Pair{String, String}, Float64}


function collect_files_to_watch()::NamedTuple

end
