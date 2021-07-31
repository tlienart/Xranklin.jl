function process_md_defs(
            mdl::Module,
            code::SS;
            context::Context=cur_lc()
            )::Vector{Symbol}

    isempty(code) && return
    # parse code
    exs = parse_code(code)
    try
        foreach(ex -> Core.eval(mdl, ex), exs)
    catch
        msg = """
              Page Var assignment
              -------------------
              Encountered an error while trying to evaluate one or more page
              variable definitions.
              """
        @warn msg
        env(:strict_parsing)::Bool && throw(msg)
    end
    # get the variable names from all assignment expressions
    vnames = [ex.args[1] for ex in exs if ex.head == :(=)]
    filter!(v -> v isa Symbol, vnames)
    for vname in vnames
        setvar!(context, vname, getproperty(mdl, vname))
    end
    return vnames
end

html_md_def(b, c)  = (add_vars!(c, content(b)); "")
latex_md_def(b, c) = (add_vars!(c, content(b)); "")
html_md_def_block  = html_md_def
latex_md_def_block = latex_md_def
