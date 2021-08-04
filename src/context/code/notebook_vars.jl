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
    # then these pages must eventually be re-triggered.
    if cntr ≤ lnb
        pruned_vars  = prune_vars_bindings(ctx)
        updated_vars = union!(pruned_vars, vnames)
        if !isempty(updated_vars)
            gc = getglob(ctx)
            id = getid(ctx)
            for (rpath, sctx) in gc.children_contexts
                id == rpath && continue
                trigger = id in keys(sctx.req_vars) &&
                            anymatch(sctx.req_vars[id], updated_vars)
                if trigger
                    union!(ctx.to_trigger, [rpath])
                end
            end
        end
    end

    # assign the variables
    for vname in vnames
        setvar!(ctx, vname, getproperty(nb.mdl, vname))
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
