"""
    serve(; kw...)

Runs Franklin in the current directory.
"""
function serve(;
            clear::Bool         = false,
            single::Bool        = true,
            )

    watched_files = collect_files_to_watch()

    full_pass(watched_files)
end





function full_pass()
end
