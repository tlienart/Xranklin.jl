# ------------------------------------------------
# FOR-style h-env
# > resolve the scope with a context in which the
#    variable(s) from the iterator are inserted
#
# {{ for (x, y) in iter}}
#     foo {{x}} bar {{y}}
# {{end}}
#
# Special cases:
#   - 'iter' can be an estring
#   - access can be via an estring
#
# {{for a in e"[1, 4]"}}
#     {{a}} (from {{> sqrt($a)}})
# {{end}}
#
function resolve_henv_for(
            lc::LocalContext,
            io::IOBuffer,
            henv::Vector{HEnvPart},
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
    # NOTE: need to limit the split in case there's an e-string with itself
    # an iterator in there! {{for x in e"[i for i in 1:2]"}}
    argiter    = join(henv[1].args, " ")
    vars, istr = strip.(split(argiter, " in ", limit=2))

    # recover the iterator, either from an e-string or from a variable
    if is_estr(istr)
        res = eval_str(lc, istr)
        if !res.success
            write(io, hfun_failed(lc, "for", henv[1].args))
            return
        else
            iter = res.value
        end
    else
        iter = getvar(lc, Symbol(istr))
    end

    if !hasmethod(iterate, tuple(typeof(iter)))
        @warn """
            {{for ...}}
            -----------
            The object corresponding to '$istr' is not iterable.
            """
        write(io, hfun_failed(lc, "for", henv[1].args))
        return
    end

    # "a"         => [:a]
    # "(a)"       => [:a]
    # "(x, y, z)" => [:x, :y, :z]
    vars = strip.(split(strip(vars, ['(', ')']), ",")) .|> Symbol

    # check if there are vars with the same name in local context, if
    # so, save them (because we'll overwrite them to resolve the for)
    # note that we filter to see if the var is in the direct context
    # (so not the global context associated with loc)
    cvars = union(keys(lc.vars), keys(lc.vars_aliases))
    saved_vars = [
        v => getvar(lc, v)
        for v in vars if v in cvars
    ]

    # For each element of iter, evaluate the scope with the updated
    # value for the variable(s)
    if length(vars) == 1
        # avoid too much unpacking, see issue #190
        for vals in iter
            setvar!(lc, vars[1], vals)
            write(io, html2(scope, lc))
        end
    else
        for vals in iter
            for (name, value) in zip(vars, vals)
                setvar!(lc, name, value)
            end
            write(io, html2(scope, lc))
        end
    end

    # reinstate or destroy bindings
    for (name, value) in saved_vars
        if value === nothing
            delete!(lc.vars, name)
        else
            lc.vars[name] = value
        end
    end
    return
end
