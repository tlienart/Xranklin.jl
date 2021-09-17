function convert_list(io::IOBuffer, g::Group, c::Context;
                      tohtml=true, kw...)::Nothing

    # Go over each blocks in g.blocks
    #   > ITEM_U_CAND, validate, get level, act on UL/OL
    #       grab raw text on line
    #       grab raw text of any subsequent inline blocks
    #       form overall string of that item, use convert_md and write in the <li></li>
    # same for ITEM_O_CAND
    #
    # validity
    #
    # ITEM_U_CAND is never invalid (marker + space)
    # ITEM_O_CAND is invalid if it's not followed by a space (i.e. "1. " or "1) ")
    #
    # (this might be revisited)
    # ---------------------------------------------------------------------------------

    return
end

# XXX XXX XXX XXX XXX XXX XXX XXX
# Note that if a group with role LIST actually has a single entry
# which really is just a textblock, it will be separated from an
# existing paragraph, we will not change this.

# The blocks in a LIST can be
# ITEM_U_CAND   (starts with +-* )
# ITEM_O_CAND   (starts with 0-9.))
# TEXT (goes with previous item)
#
# XXX XXX XXX XXX XXX XXX XXX XXX
#
# 1)foo (space missing)
# 1) foo
# 1) foo
#
# *foo (space missing)
# * * foo (ok in CM not in Franklin)
#
# * a
#   * bc
#   * d
#     * e
#
# 1) abc
#   1) def (not enough)
#
# ---
#
# 1) abc
#    1) ghi
#       * hello
# XXX XXX XXX XXX XXX XXX XXX XXX
#
# NOTE: cannot have a command generate list item like \it{foo}
#
