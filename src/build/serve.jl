"""
    serve(; kw...)

Runs Franklin in the current directory.
"""
function serve(;
            clear::Bool         = false,
            single::Bool        = true,
            folder::String      = pwd(),
            )

    set_paths(folder)
    gc = DefaultGlobalContext()

    # check if there's a config file and process it, this must happen prior
    # to everything as it defines 'ignore' for instance which is needed in
    # the watched_files step
    process_config(gc)

    watched_files = find_files_to_watch(folder)

    full_pass(watched_files; gc=gc)
end


function full_pass(watched_files; gc=env(:cur_global_ctx))
    process_config(gc)
    hasindex = isfile(path(:folder)/"index.md") ||
               isfile(path(:folder)/"index.html")
    if !hasindex
        @warn """
            Full pass
            ---------
            No 'index.md' or 'index.html' found in the base folder.
            There should be one though this won't block the generation.
            """
    end
    start = time()
    @info """
        💡 $(hl("starting the full pass", :yellow))
        """
    for (case, dict) in watched_files
        case == :md || continue    # only md processing allowed for now
        for (fpair, t) in dict
            process_file(fpair, case, t, gc=gc)
        end
    end
    @info """
        💡 $(hl("full pass done", :yellow)) $(hl(time_fmt(time()-start)))
        """
end
