
# ------------------------------------------------
# FOR-style h-env
# > resolve the scope with a context in which the
#    variable(s) from the iterator are inserted
function resolve_henv_for(
            io::IOBuffer,
            henv::Vector{HEnvPart},
            c::Context
        )::Nothing

    # scope of the loop
    scope = subs(
        parent_string(henv[1].block),
        next_index(henv[1].block),
        prev_index(henv[end].block)
    ) |> string

    # CASES
    # A. {{for x in iter}}       --> transformed to {{for (x) in iter}}
    # B. {{for (x, y) in iter}}
    #
    # so basically transform things so that we're in case B
    #
    argiter    = join(henv[1].args, " ")
    vars, istr = strip.(split(argiter, " in "))

    # recover the iterator, either from an e-string or from a variable
    if is_estr(istr)
        iter = eval_str(istr)
        if iter isa EvalStrError
            @warn """
                {{ for ... }}
                -------------
                The e-string '$istr' expected to give an iterator failed
                to evaluate properly.
                """
            write(io, hfun_failed("for", henv[1].args))
            return
        end
    else
        iter = getvar(c, Symbol(istr))
    end

    # "a"         => [:a]
    # "(a)"       => [:a]
    # "(x, y, z)" => [:x, :y, :z]
    vars = strip.(split(strip(vars, ['(', ')']), ",")) .|> Symbol

    # check if there are vars with the same name in local context, if
    # so, save them (because we'll overwrite them to resolve the for)
    # note that we filter to see if the var is in the direct context
    # (so not the global context associated with loc)
    cvars = union(keys(c.vars), keys(c.vars_aliases))
    saved_vars = [
        v => getlvar(v)
        for v in vars if v in cvars
    ]

    # For each element of iter, evaluate the scope with the updated
    # value for the variable(s)
    for vals in iter
        for (name, value) in zip(vars, vals)
            setvar!(c, name, value)
        end
        write(io, html2(scope, c))
    end

    # reinstate or destroy bindings
    for (name, value) in saved_vars
        if value === nothing
            delete!(c.vars, name)
        else
            c.vars[name] = value
        end
    end
    return
end
