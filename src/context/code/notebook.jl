# Notebook functionalities are all via the the context in which
# the notebook is.

counter(nb::Notebook)        = nb.cntr_ref[]
Base.length(nb::Notebook)    = length(nb.code_pairs)
increment!(nb::Notebook)     = (nb.cntr_ref[] += 1)
reset_counter!(nb::Notebook) = (nb.cntr_ref[] = 1)

"""
    reset_notebook_counters!(ctx)

Reset the counter of each of the context's notebook.
"""
function reset_notebook_counters!(c::Context)
    reset_counter!(c.nb_vars)
    reset_counter!(c.nb_code)
    return
end

# --------------------------------------------- #
# UTILS FOR eval_vars_cell! AND eval_code_cell! #
# --------------------------------------------- #

# check if there's a match between what had been previously evaluated
# (if anything) and the code cell to be evaluated. If it matches
# skip the cell.
function isunchanged(nb::Notebook, cntr::Int, code::String)
    return code == get(nb.code_pairs, cntr, (code="",)).code
end

function finish_cell_eval!(nb::Notebook, cp)
    cntr = counter(nb)
    lnb  = length(nb)
    if cntr ≤ lnb
       # replace, leave the counter where it was and discard
       # everything after (gets re-evaled)
       nb.code_pairs[cntr] = cp
       deleteat!(nb.code_pairs, cntr+1:lnb)
   else
       push!(nb.code_pairs, cp)
   end
   increment!(nb)
   return
end


function serialize_notebok(nb::VarsNotebook, fpath::String)
    length(nb) == 0 && return
    open(fpath, "w") do outf
        JSON3.write(outf, nb.code_pairs)
    end
    return
end

function serialize_notebok(nb::CodeNotebook, fpath::String)
    length(nb) == 0 && return
    open(fpath, "w") do outf
        JSON3.write(outf,
            (
                code_pairs=nb.code_pairs,
                code_map=nb.code_map
            )
        )
    end
    return
end

# No file check, we know the file exists
# No emptying of the code pairs, it's assumed to be empty
function deserialize_notebook!(nb::VarsNotebook, fpath::String)
    open(fpath, "r") do inf
        json = JSON3.read(inf)
        for cell in json
            push!(nb.code_pairs,
                VarsCodePair(
                    (
                        cell.code,
                        Symbol.(cell.vars)
                        )
                )
            )
        end
    end
    stale_notebook!(nb)
    return
end

function deserialize_notebook!(nb::CodeNotebook, fpath::String)
    open(fpath, "r") do inf
        json = JSON3.read(inf)
        for cell in json.code_pairs
            push!(nb.code_pairs,
                CodeCodePair(
                    (
                        cell.code,
                        CodeRepr(
                            (
                                cell.repr.html,
                                cell.repr.latex
                            )
                        )
                    )
                )
            )
        end
        for cm in json.code_map
            nb.code_map[string(cm.first)] = cm.second
        end
    end
    stale_notebook!(nb)
    return
end
