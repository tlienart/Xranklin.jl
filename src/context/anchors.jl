#=

Page defining anchors
---------------------

- upon defining any anchor --> adds those to GC via add_anchor
- upon removing any anchor --> remove anchor loc from GC via rm_anchor + trigger
                               pages that were depending on this anchor

Page querying anchors
---------------------

- anchor is around --> return corresponding target
- anchor is not around and we're in initial pass --> mark page as re-trigger
- anchor is not around --> return '#'

=#


"""
    add_anchor(gc, id, rpath)

Add an anchor with a given id defined on page rpath to the global context.
If the id is already present, push the source to the anchor's locs.
Otherwise add a new anchor to the GC.

Note: in this page the 'rpath' is that of the page defining the anchor.
"""
function add_anchor(gc::GlobalContext, id::String, rpath::String)::Nothing
    crumbs("add_anchor", "$id (from $rpath)")
    # add the id to the local context's anchors
    union!(gc.children_contexts[rpath].anchors, [id])
    if id in keys(gc.anchors)
        # generally there'll be one, possibly a couple of
        # locs so it's not very expensive to go over the whole vector
        locs = gc.anchors[id].locs
        # do what's needed to get rpath at the end of locs
        if rpath ∉ locs
            push!(locs, rpath)
        elseif last(locs) != rpath
            # re-order so that rpath is the last one
            prev = copy(locs)
            empty!(locs)
            append!(locs, [l for l in prev if l != rpath])
            push!(locs, rpath)
        end
    else
        gc.anchors[id] = Anchor(id, rpath)
    end
    return
end


"""
    get_anchor(gc, id, rpath)

Try to get the target corresponding to a global anchor id from a LC associated
with rpath.

Note: in this case the 'rpath' is that of the page querying for the anchor.

1. there is a matching id in gc.anchors, return that.
2. there isn't a matching id and we're on the full pass, we might not yet have
    seen a page that defines the anchor so mark the current page as re-trigger
    after the full pass.
3. there isn't a matching id and we're not on the full pass, return '#'.

In case (1), the local context corresponding to the last location of the
matching anchor gets the querying page as a to-trigger.
"""
function get_anchor(gc::GlobalContext, id::String, rpath::String)::String
    crumbs("get_anchor", "$id (from $rpath)")
    if id in keys(gc.anchors)
        a = gc.anchors[id]
        union!(a.reqs, [rpath])
        # Return the target link e.g. 'foo/bar/#anchor_id'. The last loc is
        # always used. This is why it's recommended to only have unique global ids;
        # if there's more than one loc for one id, it's ambiguous which target will be
        # obtained where.
        if length(a.locs) > 1
            @warn """
                Anchor target
                There is more than one page with an anchor '$(a.id)'.
                The last seen page defining it is: $(last(a.locs)).
                """
        end
        # form the target
        # 1. start with a `/` so it's not appended to the current path
        # 2. use the unixified relative path to the source
        # 3. add the anchor on that page
        target = '/' * unixify(noext(last(a.locs))) * "#$(a.id)"
        return target
    end
    # this is only used in FP and otherwise has no effect
    union!(gc.init_trigger, [rpath])
    return "#"
end


"""
    rm_anchor(gc, id, rpath)

Remove 'rpath' from the anchor (id)'s locations. If there's no other location,
remove the anchor altogether; otherwise the last remaining location becomes
the one attached to that id.

Note: in this case the 'rpath' is the one of the page removing an anchor.

Re-process all pages that depended upon this updated anchor assuming the
removed location was the last one.
"""
function rm_anchor(gc::GlobalContext, id::String, rpath::String)
    crumbs("rm_anchor", "$id (from $rpath)")
    # this check should be superfluous
    id in keys(gc.anchors) || return
    # recover the locs and the last relevant loc
    locs = gc.anchors[id].locs
    cloc = last(locs)
    reqs = copy(gc.anchors[id].reqs)
    prev = copy(locs)
    empty!(locs)
    append!(locs, [l for l in prev if l != rpath])
    if isempty(locs)
        delete!(gc.anchors, id)
    end
    for rp in reqs
        reprocess(rp, gc; msg="(depends on updated anchor)")
    end
    return
end
