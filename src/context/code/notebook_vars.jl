"""
    eval_vars_cell!(ctx, cell_code)

Evaluate the content of a cell we know assigns a bunch of page variables.
"""
function eval_vars_cell!(ctx::Context, cell_code::SS)::Nothing
    isempty(cell_code) && return

    nb   = ctx.nb_vars
    cntr = counter(nb)
    lnb  = length(nb)
    h    = hash(cell_code)

    # skip cell if previously seen and unchanged
    isunchanged(nb, cntr, h) && (increment!(nb); return)

    # eval cell and recover the names of the variables assigned
    vnames = _eval_vars_cell(nb.mdl, cell_code, ctx)

    # if some variables change and other pages are dependent upon them
    # then these pages must be re-triggered.
    if cntr ≤ lnb
        pruned_bindings  = prune_vars_bindings(ctx)
        updated_bindings = union!(pruned_bindings, vnames)
        trigger_dependent_pages(ctx, updated_bindings)
    end
    return finish_cell_eval!(nb, CodePair((h, vnames)))
end


"""
    _eval_vars_cell(mdl, code, ctx)

Helper function to `eval_vars_cell!`. Returns the list of symbols matching the
variables assigned in the code.
"""
function _eval_vars_cell(mdl::Module, code::SS, ctx::Context)::Vector{Symbol}
    exs = parse_code(code)
    try
        start = time(); @debug """
        ⏳ evaluating vars cell...
        """
        foreach(ex -> Core.eval(mdl, ex), exs)
        δt = time() - start; @debug """
            ... [vars cell] ✔ $(hl(time_fmt(δt)))
            """
    catch
        msg = """
              Page Var assignment
              -------------------
              Encountered an error while trying to evaluate one or more page
              variable definitions.
              """
        if env(:strict_parsing)::Bool
            throw(msg)
        else
            @warn msg
        end
    end
    # get the variable names from all assignment expressions
    vnames = [ex.args[1] for ex in exs if ex.head == :(=)]
    filter!(v -> v isa Symbol, vnames)
    for vname in vnames
        setvar!(ctx, vname, getproperty(mdl, vname))
    end
    return vnames
end


"""
    prune_vars_bindings(ctx)

Let's say that on pass one, there was a block defining `a=5; b=7` but then
on pass two, that the block only defines `a=5`, the binding to `b` should be
removed from the relevant context.
"""
function prune_vars_bindings(ctx::Context)::Vector{Symbol}
    pruned_bindings = Symbol[]

    nb   = ctx.nb_vars
    cntr = counter(nb)
    for i in cntr:length(nb)
        cp = nb.code_pairs[i]
        append!(pruned_bindings, cp.result)
    end
    unique!(pruned_bindings)

    # Remove all bindings apart from the ones that have a default value in
    # which case, use that default.
    defaults = ifelse(isglob(ctx), DefaultGlobalVars, DefaultLocalVars)
    keys_defaults = keys(defaults)
    bindings_with_default = [b for b in pruned_bindings if b in keys_defaults]
    for b in pruned_bindings
        delete!(ctx.vars, b)
        if b in keys_defaults
            ctx.vars[b] = defaults[b]
        end
    end
    return pruned_bindings
end


"""
    trigger_dependent_pages(gc, updated_bindings)

When changing variables on a page (or `config.md`), other pages which depend
on these variables must be updated as well.
"""
function trigger_dependent_pages(
            ctx::Context,
            updated_bindings::Vector{Symbol}
            )::Nothing
    # recover the relevant global context
    gc = getglob(ctx)
    # look at all sister context, check the ones that indicate they depend
    # upon ctx and check if they depend on a variable that was updated
    for (rpath, sctx) in gc.children_contexts
        rpath == ctx.rpath && continue
        # check if the page depends on something from this context
        trigger = ctx.rpath in keys(sctx.req_vars) &&
                    any(a == b for a in sctx.req_vars[ctx.rpath], b in updated_bindings)
        if trigger
            start = time(); @info """
            ... updating $(hl(id, :cyan)) as it depends on a var that changed
            """
            process_md_file(gc, id)
            @info """
                ... ... ✔ $(hl(time_fmt(time()-start)))
                """
        end
    end
    return
end
