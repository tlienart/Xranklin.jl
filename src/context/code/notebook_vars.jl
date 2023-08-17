"""
    eval_vars_cell!(ctx, cell_code)

Evaluate the content of a cell we know assigns a bunch of page variables.

## Trigger

If a cell is seen that has changed, then trigger all pages that depend on the
union of past and current assignments of that cell. Also mark all cells
after that one as to re-evaluate (as they may depend on vars that have changed
even though the code stays the same).
"""
function eval_vars_cell!(
            ctx::Context,
            cell_code::SS
        )::Nothing
    isempty(cell_code) && return

    

    if ctx isa LocalContext && ctx !== cur_lc()
        set_current_local_context(ctx)
    end

    nb   = ctx.nb_vars
    cntr = counter(nb)
    lnb  = length(nb)
    code = cell_code |> sstrip

    # skip cell if previously seen and unchanged
    if isunchanged(nb, cntr, code)
        increment!(nb)
        return
    end

    if is_stale(nb)
        # Reeval all previous cells. We don't need to keep track
        # of their vars or whatever as they haven't changed
        tempc = 1
        while tempc < cntr
            _eval_vars_cell(
                nb.mdl,
                nb.code_pairs[tempc].code
            )
            tempc += 1
        end
        fresh_notebook!(nb)
    end

    # Here we're about to evaluate a cell which is either new or has changed
    # since last eval.
    # Since that cell (or following ones) may have dropped some variable
    # assignments, we reset all variable assignments:
    #   - either we remove them, or
    #   - we assign them to their default value if they have one
    # Then we remove all code pairs after the current counter.
    existing_assignments = Symbol[]
    for i in cntr:lnb
        cp = nb.code_pairs[i]
        append!(existing_assignments, [vp.var for vp in cp.vars])
    end

    if !isempty(existing_assignments)
        unique!(existing_assignments)
        defaults      = is_glob(ctx) ? DefaultGlobalVars : DefaultLocalVars
        keys_defaults = keys(defaults)
        for a in existing_assignments
            if a in keys_defaults
                ctx.vars[a] = defaults[a]
            else
                delete!(ctx.vars, a)
            end
        end
        deleteat!(nb.code_pairs, cntr:lnb)
    end

    
    

    # eval cell and recover the names of the variables assigned
    vpairs   = _eval_vars_cell(nb.mdl, code)
    vnames   = [vp.var for vp in vpairs]

    
    

    # list of all variables that either have just been assigned
    # or were removed/reset through the existing_assignments phase
    all_vars = union!(existing_assignments, vnames)

    if ctx isa LocalContext
        # check if another page calls one of those variables
        # in all_vars and if so, mark for retrigger
        gc = get_glob(ctx)

        for other_lc in values(gc.children_contexts)
            # skip current one
            ctx === other_lc && continue
            # for other check if
            # 1. current page is marked as requested from in other page
            # 2. if (1) check if there's an overlap between the vars that have
            #    changed and the ones that are requested
            trigger = other_lc.rpath in keys(ctx.req_vars) &&
                      anymatch(ctx.req_vars[other_lc.rpath], all_vars)
            trigger && union!(ctx.to_trigger, [other_lc.rpath])
        end
    end

    # assign the variables to the context
    for vp in vpairs
        setvar!(ctx, vp.var, vp.value)
    end

    # finalise
    finish_cell_eval!(nb, VarsCodePair((code, vpairs)))

    

    return
end


"""
    _eval_vars_cell(mdl, code, ctx)

Helper function to `eval_vars_cell!`. Returns the list of symbols matching the
variables assigned in the code.
"""
function _eval_vars_cell(
        mdl::Module,
        code::String
        )::Vector{VarPair}

    exs = parse_code(code)
    res = eval_nb_cell(mdl, code)

    res.success || return Vector{VarPair}()

    # get the variable names from all assignment expressions
    vnames = []
    for ex in exs
        if ex.head == :(=)
            push!(vnames, ex.args[1])
        elseif ex.args[1] isa Expr && ex.args[1].head == :(=)
            push!(vnames, ex.args[1].args[1])
        end
    end
    return [
        VarPair((vn, getproperty(mdl, vn)))
        for vn in vnames if vn isa Symbol
    ]
end
