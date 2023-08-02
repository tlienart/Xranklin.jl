"""
    process_md_file_pass_i(lc)

Processing of tags and anchors.
"""
function process_md_file_pass_i(
            lc::LocalContext
        )::Nothing

    crumbs(@fname)

    # Note that here lc is not necessarily equal to cur_lc
    # unlike in pass_1 where this is guaranteed by the fact
    # that the pass 1 is called directly after process_file
    # which makes sure of it.
    # For the intermediate file though we don't care because
    # there's no Utils-style processing.

    gc    = lc.glob
    rpath = lc.rpath

    # Anchors to remove
    __t = tic()
    default = Set{String}()
    for id in getvar(lc, :_rm_anchors, default)
        rm_anchor(gc, id, rpath)
    end
    setvar!(lc, :_rm_anchors, default)
    toc(__t, "mdi / remove anchors")

    # Tags to remove
    __t = tic()
    for id in getvar(lc, :_rm_tags, default)
        rm_tag(gc, id, rpath)
    end
    setvar!(lc, :_rm_tags, default)
    toc(__t, "mdi / remove tags")

    # Tags to add
    __t = tic()
    default = Pair{String}[]
    for (id, name) in getvar(lc, :_add_tags, default)
        add_tag(gc, id, name, rpath)
    end
    setvar!(lc, :_add_tags, default)
    toc(__t, "mdi / add tags [$rpath]")
    return
end
