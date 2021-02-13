"""
$SIGNATURES

After the partitioning, latex objects are not quite formed; they need to be merged into
larger objects including the relevant braces.
The function gradually goes over the blocks, adds new latex definitions to the context
and assembles latex commands and environments based on existing definitions.
"""
function assemble_latex_objects!(parts::Vector{Block}, ctx::Context)
    index_to_remove = Int[]
    for part in parts
        part.name in (:) || continue
    end
    # remove the blocks that have been merged
    deleteat!(parts, index_to_remove)
    return
end
