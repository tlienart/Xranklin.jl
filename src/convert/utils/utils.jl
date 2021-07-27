utils_module_name() = "Utils_$(valueglob(:_utils_mod_cntr, 0))"
utils_module_symb() = Symbol(utils_module_name())
utils_module()      = getproperty(Main, utils_module_symb())
new_utils_module()  = newmodule(utils_module_name())

utils_hfun_names()  = valueglob(:_utils_hfun_names)::Vector{Symbol}
utils_lxfun_names() = valueglob(:_utils_lxfun_names)::Vector{Symbol}
utils_var_names()   = valueglob(:_utils_var_names)::Vector{Symbol}


function process_utils(utils::String)
    h = hash(utils)
    h == valueglob(:_utils_mod_hash, zero(UInt64)) && return
    # keep track of the hash
    setgvar!(:_utils_mod_hash, h)
    # increment module counter
    setgvar!(:_utils_mod_cntr, valueglob(:_utils_mod_cntr, 0) + 1)
    # create new module and load script into it
    m = newmodule(utils_module_name())
    Base.include_string(m, utils)
    # check names of hfun, lx and vars
    ns = String.(names(m, all=true))
    filter!(n -> n[1] != '#' && n ∉ ("eval", "include"), ns)
    setgvar!(:_utils_hfun_names,
                Symbol.([n[6:end] for n in ns if startswith(n, "hfun_")]))
    setgvar!(:_utils_lxfun_names,
                Symbol.([n[4:end] for n in ns if startswith(n, "lx_")]))
    setgvar!(:_utils_var_names,
                Symbol.([n for n in ns if !startswith(n, r"lx_|hfun_|Utils_")]))
    return
end

function process_utils()
    utils_path = path(:folder) / "utils.jl"
    if isfile(utils_path)
        process_utils(read(utils_path, String))
    else
        @info "❎ no utils file found."
    end
    return
end
