"""
    serve(; kw...)

Runs Franklin in the current directory.
"""
function serve(;
            clear::Bool         = false,
            single::Bool        = true,
            folder::String      = pwd(),
            )

    gc = DefaultGlobalContext()
    set_paths(folder)

    # check if there's a config file and process it, this must happen prior
    # to everything as it defines 'ignore' for instance which is needed in
    # the watched_files step
    process_config(gc)

    watched_files = find_files_to_watch(folder)

    full_pass(watched_files; gc=gc)

    # wipe parent module (make all children modules inaccessible so that GC
    # should be able to destroy them)
    parent_module(wipe=true)
    return
end


"""
    full_pass(watched_files; gc)

Perform a full pass over a set of watched files: each of these is then
processed in the `gc` context.

DEV NOTE: we could use multithreadding here but the overhead for a typical
website compared to how much time it takes to do things sequentially is
prohibitive. It would be much better to invest in saving a previous context
for warm-loading.

## KW-Args

    gc: global context in which to do the full pass
    skip: list of file pairs to ignore in the pass
"""
function full_pass(
            watched_files::LittleDict{Symbol, TrackedFiles};
            gc::GlobalContext=cur_gc(),
            skip_files::Vector{Pair{String, String}}=Pair{String, String}[]
            )::Nothing
    # make sure the context considers the config file
    process_config(gc)

    # check that there's an index page (this is what the server will
    # expect to point to)
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

    # Go over all the watched files and run `process_file` on them.
    start = time()
    @info """
        💡 $(hl("starting the full pass", :yellow))
        """
    for (case, dict) in watched_files, (fp, t) in dict
        process_file(fp, case, dict[fp], gc=gc, skip=skip_files)
    end
    @info """
        💡 $(hl("full pass done", :yellow)) $(hl(time_fmt(time()-start)))
        """
    return
end


#=
NOTE

loop
- use prune_children! 

=#
