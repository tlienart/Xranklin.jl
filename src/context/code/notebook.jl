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

"""
    reset_code_notebook!(c::Context)

Clear code notebooks so that it can be re-evaluated from scratch in case the
page variable `ignore_cache` is used for instance.
"""
function reset_code_notebook!(c::LocalContext)
    reset_counter!(c.nb_code)
    empty!(c.nb_code.code_pairs)
    empty!(c.nb_code.code_map)
    fresh_notebook!(c.nb_code)
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
