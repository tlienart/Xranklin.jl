function process_utils(
            utils::String,
            gc::GlobalContext=cur_gc()
            )

    start = time(); @info """
        ⌛ processing utils
        """

    # check to see if utils has changed since last we saw it
    h = hash(utils)
    h == value(gc, :_utils_mod_hash)::UInt64 && return
    setvar!(gc, :_utils_mod_hash, h)

    # create new module and load script into it, we want the module to
    # be wiped so that there's no undue reliance upon old-definitions.
    # as a result, we don't need to softscope here
    m = utils_module(wipe=true)
    include_string(m, utils)

    # check names of hfun, lx and vars; since we wiped the module before the
    # include_string, all the proper names recuperated here are 'fresh'.
    ns = String.(names(m, all=true))
    filter!(
        n -> n[1] != '#' &&
             n ∉ ("eval", "include", string(UTILS_MODULE_NAME)),
        ns
    )
    setvar!(gc, :_utils_hfun_names,
                Symbol.([n[6:end] for n in ns if startswith(n, "hfun_")]))
    setvar!(gc, :_utils_lxfun_names,
                Symbol.([n[4:end] for n in ns if startswith(n, "lx_")]))
    setvar!(gc, :_utils_var_names,
                Symbol.([n for n in ns if !startswith(n, r"lx_|hfun_")]))

    @info """
        ... ✔ $(hl(time_fmt(time()-start)))
        """
    return
end

function process_utils(gc::GlobalContext=cur_gc())
    utils_path = path(:folder) / "utils.jl"
    if isfile(utils_path)
        process_utils(read(utils_path, String), gc)
    else
        @info "❎ no utils file found."
    end
    return
end

utils_hfun_names()  = valueglob(:_utils_hfun_names)::Vector{Symbol}
utils_lxfun_names() = valueglob(:_utils_lxfun_names)::Vector{Symbol}
utils_var_names()   = valueglob(:_utils_var_names)::Vector{Symbol}
