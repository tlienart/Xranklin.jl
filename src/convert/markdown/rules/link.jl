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
    tokens = FP.subv(FP.default_md_tokenizer(ss))
    is_active = ones(Bool, length(tokens))
    # find priority containers and deactivate stuff in it (e.g. code)
    FP._find_blocks!(blocks, tokens, FP.MD_PASS1_TEMPLATES, is_active,
                     process_linereturn=false)
    # go through tokens and pick the relevant ones for the link
    tokens = [t for t in tokens if t.name ∉ (:SOS, :EOS)]
    i = 1
    n = length(tokens)
    link_a_open   = FP.EMPTY_TOKEN
    link_a_close  = FP.EMPTY_TOKEN
    link_ab_mid   = FP.EMPTY_TOKEN
    link_ab_close = FP.EMPTY_TOKEN
    while i <= n
        if is_active[i]
            t = tokens[i]
            # if it's the first [ --> link_a_open
            if t.name == :SQ_BRACKET_OPEN && isempty(link_a_open)
                link_a_open = t
            # if it's the last token and ] --> link_a_close
            # if it's not the last token and ] and the next token is ( --> link_ab_mid
            # (note that this second one will overwrite so it should take the last one
            # corner case is if there's ]( in the URL itself...)
            elseif t.name == :SQ_BRACKET_CLOSE
                if i == n
                    link_a_close = t
                elseif tokens[i+1].name == :BRACKET_OPEN
                    link_ab_mid = FP.Token(
                    :LINK_AB_MID,
                    subs(ss, from(t), to(tokens[i+1]))
                    )
                end
            # if it's the last token and ) --> link_ab_close
            elseif t.name == :BRACKET_CLOSE && i == n
                link_ab_close = t
            end
        end
        i += 1
    end
    return (; link_a_open, link_a_close, link_ab_mid, link_ab_close)
end

function _link_gen(ref, title; tohtml=true)
    tohtml && return """
        <a href="$ref">$title</a>
        """
    return """
        \\href{$ref}{$title}
        """
end

function _link_a(b::Block, c::Context; tohtml=true)
    ss = b.ss
    t  = _link_blocks(ss)
    t1 = t.link_a_open
    t2 = t.link_a_close

    title = subs(ss, next_index(t1), prev_index(t2))
    ref = string_to_anchor(title)
    title = convert_md(title, c; tohtml, nop=true)

    _link_gen(ref, title; tohtml)
end

function _link_ab(b::Block, c::Context; tohtml=true)
    ss = b.ss
    t  = _link_blocks(ss)
    t1 = t.link_a_open
    t2 = t.link_ab_mid
    t3 = t.link_ab_close

    title = subs(ss, next_index(t1), prev_index(t2))
    title = convert_md(title, c; tohtml, nop=true)
    ref   = subs(ss, next_index(t2), prev_index(t3))
    ref   = normalize_uri(ref)

    _link_gen(ref, title; tohtml)
end

# The link_a may refer to something indicated further
# and therefore need to be reprocessed at HTML phase
html_link_a(b::Block, c::LocalContext)  = _link_a(b, c; tohtml=true)
html_img_a(b::Block, _)   = ""
latex_link_a(b::Block, c::LocalContext) = _link_a(b, c; tohtml=false)
latex_img_a(b::Block, _)  = ""

html_link_ab(b::Block, c::LocalContext)  = _link_ab(b, c; tohtml=true)
latex_link_ab(b::Block, c::LocalContext) = _link_ab(b, c; tohtml=false)
# html_img_ab(b::Block, _) = ...
# latex_link_ab()

#function img_a(ss::SS)
# end
