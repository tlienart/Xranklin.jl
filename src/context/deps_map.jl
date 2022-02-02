"""
    DepsMap

FWD: rpath_md1 => [rpath_f1, rpath_f2, ...]    e.g. page.md     => [literate.jl]
BWD: rpath_f1  => [rpath_md1, rpath_md2, ...]  e.g. literate.jl => [page.md]
hashes: {rpath_f1 => filehash}                 e.g. literate.jl => 0xb141aac7
"""
struct DepsMap
    fwd::LittleDict{String, Set{String}}
    fwd_keys::Set{String}                   # all pages with deps
    bwd::LittleDict{String, Set{String}}
    bwd_keys::Set{String}                   # all deps
    hashes::LittleDict{String, UInt32}
end
DepsMap() = DepsMap(
    LittleDict{String, Set{String}}(),
    Set{String}(),
    LittleDict{String, Set{String}}(),
    Set{String}(),
    LittleDict{String, UInt32}()
)

function push!(dm::DepsMap, a::String, b::String)
    @debug "➕ adding dependency '$a' <=> '$b'."
    # Forward (add file 'b' to dependencies of a)
    if a in dm.fwd_keys
        union!(dm.fwd[a], [b])
    else
        dm.fwd[a] = Set([b])
        union!(dm.fwd_keys, [a])
    end
    # Backwards (add file 'a' to requesters of 'b')
    if b in dm.bwd_keys
        union!(dm.bwd[b], [a])
    else
        dm.bwd[b] = Set([a])
        union!(dm.bwd_keys, [b])
    end
    # Hash of b (might exist already, that's fine)
    dm.hashes[b] = filehash(path(:folder) / b)
    return
end

function delete!(dm::DepsMap, c::String)
    msg = "🗑️ removing $c from the gc.deps_map as it was deleted."
    if c in dm.fwd_keys
        @info msg
        for k in dm.fwd[c]
            setdiff!(dm.bwd[k], [c])
            if isempty(dm.bwd[k])
                delete!(dm.bwd, k)
                setdiff!(dm.bwd_keys, [k])
                delete!(dm.hashes, k)
            end
        end
        delete!(dm.fwd, c)
        setdiff!(dm.fwd_keys, [c])
    elseif c in dm.bwd_keys
        @info msg
        for k in dm.bwd[c]
            setdiff!(dm.fwd[k], [c])
            if isempty(dm.fwd[k])
                delete!(dm.fwd, k)
                setdiff!(dm.fwd_keys, [k])
            end
        end
        delete!(dm.bwd, c)
        setdiff!(dm.bwd_keys, [c])
        delete!(dm.hashes, c)
    end
    return
end

function merge!(dm::DepsMap, dm2::DepsMap)
    merge!(dm.fwd, dm2.fwd)
    union!(dm.fwd_keys, dm2.fwd_keys)
    merge!(dm.bwd, dm2.bwd)
    union!(dm.bwd_keys, dm2.bwd_keys)
    merge!(dm.hashes, dm2.hashes)
    return
end


"""
    have_changed_deps(dm)

Set of pages rpaths which have one or more dependent file (e.g. a literate
script) that has changed. This is used in the initial pass to eliminate
pages which may otherwise have been skipped if they've not changed.

E.g. if page A.md depends upon B.jl and A.md hasn't changed, then it would
be skipped. But of course this shouldn't happen if B.jl has changed.

In this example, it would be spotted that B.jl has changed and, using the
backward element of the depency map, we would return A.md in the set.
"""
function have_changed_deps(dm::DepsMap)::Set{String}
    # set of pages that have deps that have changed
    pages = Set{String}()
    # go through all deps
    for k in dm.bwd_keys
        # if the file is not there or its hash does not correspond to
        # the stored hash --> it's changed
        fp = path(:folder) / k
        haschanged = !isfile(fp) || filehash(fp) != dm.hashes[k]
        haschanged && union!(pages, dm.bwd[k])
    end
    return pages
end
