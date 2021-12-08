"""
    latex2(s, c)

Postprocess a latex string `s` in the context `c` (for the moment, this does
not do anything).

# Future

* handle reference links (see `_link_a` and `_img_a`).

"""
latex2(s::String, ::Context) = begin
    set_postprocess!(c, true)
    s
end
