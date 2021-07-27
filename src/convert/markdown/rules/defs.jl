function process_defs(cb, c)
    mdl = newmodule("__FRANKLIN_VARS")
    exs = parse_code(cb)
    run_code(mdl, cb; exs=exs, block_name="vars assignment")

    # get the variable names from all assignment expressions
    vnames = [
        ex.args[1] for ex in exs
        if (ex.head == :(=)) && (ex.args[1] isa Symbol)
    ]
    for vname in vnames
        setvar!(c, vname, getproperty(mdl, vname))
    end
end

html_md_def(b, c)  = (process_defs(content(b), c); "")
latex_md_def(b, c) = (process_defs(content(b), c); "")
html_md_def_block  = html_md_def
latex_md_def_block = latex_md_def
