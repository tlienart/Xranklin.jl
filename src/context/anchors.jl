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

If several places define an anchor, the ordering is such that the latest
viewed place will be the first one to be used. So for instance if both
page A and B define anchor `anchor`, and page B is the last page to be
built, a hyperref to `anchor` will point to B (of course, it's preferable
if pages don't redefine the same anchors but this is how it's resolved
if it happens).

Note: in this page the 'rpath' is that of the page defining the anchor.
"""
function add_anchor(
            gc::GlobalContext,
            id::String,         # anchor id
            rpath::String       # place where the anchor is defined
        )::Nothing

    crumbs(@fname, "$id (from $rpath)")

    # add the id to the local context's anchors (if it's not there already)
    union!(
        gc.children_contexts[rpath].anchors,
        [id]
    )

    # add the id to the gc anchors
    if id in keys(gc.anchors)
        anchor = gc.anchors[id]
        if anchor.cur_loc != rpath
            anchor.cur_loc = rpath
            union!(anchor.locs, [rpath])
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
function get_anchor(
            gc::GlobalContext,
            id::String,
            rpath::String
        )::String

    crumbs(@fname, "$id (from $rpath)")

    if id in keys(gc.anchors)
        anchor = gc.anchors[id]
        union!(anchor.reqs, [rpath])
        # Return the target link e.g. 'foo/bar/#anchor_id'. The last loc is
        # always used. This is why it's recommended to only have unique global
        # ids; if there's more than one loc for one id, it's ambiguous which
        # target will be obtained where.
        if length(anchor.locs) > 1
            @warn """
                Anchor target
                There is more than one page with an anchor '$(anchor.id)'.
                The last seen page defining it is: $(anchor.cur_loc).
                To avoid this being ambiguous, consider adding an explicit
                label to the desired target with `\\label{name of target}`.
                """
        end
        # form the target
        # 1. start with a `/` so it's not appended to the current path
        # 2. use the unixified relative path to the source
        # 3. add the anchor on that page
        target = '/' * unixify(noext(anchor.cur_loc)) * "#$(anchor.id)"
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
function rm_anchor(
            gc::GlobalContext,
            id::String,
            rpath::String
        )::Nothing

    crumbs(@fname, "$id (from $rpath)")

    # this check should be superfluous
    id in keys(gc.anchors) || return

    anchor = gc.anchors[id]
    reqs   = copy(anchor.reqs)

    # remove rpath from the anchor locs
    if rpath in anchor.locs
        pop!(anchor.locs, rpath)
    end
    # if it was the cur_loc, check if there's another candidate available,
    # if there isn't, remove the anchor altogether
    if anchor.cur_loc == rpath
        if isempty(anchor.locs)
            delete!(gc.anchors, id)
        else
            anchor.cur_loc = pop!(anchor.locs)
        end
    end

    # trigger pages that might have dependended on that anchor
    for rp in reqs
        process_file_from_trigger(rp, gc; msg="(depends on updated anchor)")
    end
    return
end
