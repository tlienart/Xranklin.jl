# links
#
#    * [A]     LINK_A   for <a href="ref(A)">html(A)</a>
#    * [A](B)  LINK_AB  for <a href="escape(B)">html(A)</a>
#    * ![A]    IMG_A    <img src="ref(A)" alt="esc(A)" />
#    * ![A](B) IMG_AB   <img src="escape(B)" alt="esc(A)" />
#    * [A]: B  REF      (--> aggregate B, will need to distinguish later)
#

# html_link_a
# html_link_ab
# html_img_a
# html_img_ab
# html_ref
#
# latex_link_a
# latex_link_ab
# latex_img_a
# latex_img_ab
# latex_ref


function _link_blocks(ss::SS)
    blocks = Block[]
    tokens = FP.default_md_tokenizer(ss)
    is_active = ones(Bool, length(tokens))
    # find priority containers and deactivate stuff in it (e.g. code)
    FP._find_blocks!(blocks, tokens, MD_PASS1_TEMPLATES, is_active,
                     process_linereturn=false)
    return blocks
end

function _link_a(ss::SS)
    b = _link_blocks(ss)
    # In order
    # 1. get the first `:SQ_BRACKET_OPEN`,
    # 2. get the last `:SQ_BRACKET_CLOSE`
    # XXX
end

function _link_ab(ss::SS)
    b = _link_blocks(ss)
    # In order
    # 1. get the first `:SQ_BRACKET_OPEN`,
    # 2. get the last `:SQ_BRACKET_CLOSE` immediately followed by `:BRACKET_OPEN`
    # 3. get the last `:BRACKET_CLOSE`
    # XXX
end

# The link_a may refer to something indicated further
# and therefore need to be reprocessed at HTML phase
html_link_a(b::Block, _)  = "{{link_a $(_link_a(content(b)))}}"
html_img_a(b::Block, _)   = "{{img_a $(_link_a(content(b)))}}"
latex_link_a(b::Block, _) = ""
latex_img_a(b::Block, _)  = ""

# html_link_ab(b::Block, _) = "{{link_ab }}"
# html_img_ab(b::Block, _) = ...
# latex_link_ab()

#function img_a(ss::SS)
# end
