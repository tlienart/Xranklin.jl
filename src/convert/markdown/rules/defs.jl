function process_defs(d::SS, c::Context)
    # check if the definition has already been processed and if so skip
    h = hash(d)
    h in getvar(c, :_md_def_hashes)::Set{UInt64} && return
    # otherwise add the hash of the definition and evaluate it
    union!(c.vars[:_md_def_hashes], h)
    mdl = vars_module()
    include_string(softscope, mdl, d)
    vnames = filter!(
        n -> n != nameof(mdl) &&
             string(n)[1] != "#",
        names(mdl, all=true)
    )
    for vname in vnames
        setvar!(c, vname, getproperty(mdl, vname))
    end
    return
end

html_md_def(b, c)  = (process_defs(content(b), c); "")
latex_md_def(b, c) = (process_defs(content(b), c); "")
html_md_def_block  = html_md_def
latex_md_def_block = latex_md_def
