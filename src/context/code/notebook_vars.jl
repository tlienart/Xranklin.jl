"""
    eval_vars_cell!(ctx, cell_code)

Evaluate the content of a cell we know assigns a bunch of page variables.
"""
function eval_vars_cell!(ctx::Context, cell_code::SS)::Nothing
    isempty(cell_code) && return

    nb   = ctx.nb_vars
    cntr = counter(nb)
    lnb  = length(nb)
    code = cell_code |> strip |> string

    # skip cell if previously seen and unchanged
    isunchanged(nb, cntr, code) && (increment!(nb); return)

    if isstale(nb)
        # reeval all previous cells, we don't need to
        # keep track of their vars or whatever as they haven't changed
        tempc = 1
        while tempc < cntr
            _eval_vars_cell(nb.mdl, nb.code_pairs[tempc].code, ctx)
            tempc += 1
        end
        fresh_notebook!(nb)
    end

    # eval cell and recover the names of the variables assigned
    vpairs = _eval_vars_cell(nb.mdl, code, ctx)
    vnames = [vp.var for vp in vpairs]

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
    for vp in vpairs
        setvar!(ctx, vp.var, vp.value)
    end

    return finish_cell_eval!(nb, VarsCodePair((code, vpairs)))
end


"""
    _eval_vars_cell(mdl, code, ctx)

Helper function to `eval_vars_cell!`. Returns the list of symbols matching the
variables assigned in the code.
"""
function _eval_vars_cell(mdl::Module, code::String, ctx::Context)::Vector{VarPair}
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
    vnames = []
    for ex in exs
        if ex.head == :(=)
            push!(vnames, ex.args[1])
        elseif ex.args[1] isa Expr && ex.args[1].head == :(=)
            push!(vnames, ex.args[1].args[1])
        end
    end
    filter!(v -> v isa Symbol, vnames)
    return [VarPair((vn, getproperty(mdl, vn))) for vn in vnames]
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
        append!(pruned_bindings, [vp.var for vp in cp.vars])
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
