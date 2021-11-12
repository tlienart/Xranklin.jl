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

"""
    _link_blocks(ss)

Helper function which takes a validated link-like SubString, i.e. something
with one of the following form:

    * [A](B)  -- link AB
    * [A]     -- link A  (IF there's a corresponding ref A)
    * [A]:    -- ref A
    * ![A](B) -- img AB
    * ![A]    -- img A   (IF there's a corresponding ref A)

The goal of this function is to extract the bracketed components (A, B).
"""
function _link_blocks(ss::SS)
    blocks    = Block[]
    tokens    = FP.subv(FP.default_md_tokenizer(ss))
    is_active = ones(Bool, length(tokens))
    # find priority containers and deactivate stuff in it (e.g. code)
    FP._find_blocks!(blocks, tokens, FP.MD_PASS1_TEMPLATES, is_active,
                     process_linereturn=false)
    # go through tokens and pick the relevant ones for the link
    tokens = [t
        for (i, t) in enumerate(tokens)
        if t.name ∉ (:SOS, :EOS) && is_active[i]
    ]

    i = 1
    n = length(tokens)
    link_a_open   = FP.EMPTY_TOKEN
    link_a_close  = FP.EMPTY_TOKEN
    link_ab_mid   = FP.EMPTY_TOKEN
    link_ab_close = FP.EMPTY_TOKEN
    ref_mid       = FP.EMPTY_TOKEN
    while i <= n
        t = tokens[i]
        # if it's the first [ --> link_a_open
        if t.name == :SQ_BRACKET_OPEN && isempty(link_a_open)
            link_a_open = t
        # if it's the last token and ] --> link_a_close
        # if it's not the last token and ] and the next token is ( --> link_ab_mid
        # (note that this second one will overwrite so it should take the last one
        # corner case is if there's ]( in the URL itself...)
        elseif t.name == :SQ_BRACKET_CLOSE
            if next_chars(t) == [':']
                ref_mid = FP.Token(
                    :REF_MID,
                    subs(parent_string(ss), from(t), next_index(t))
                )
            elseif i == n
                link_a_close = t
            elseif tokens[i+1].name == :BRACKET_OPEN
                link_ab_mid = FP.Token(
                    :LINK_AB_MID,
                    subs(parent_string(ss), from(t), to(tokens[i+1]))
                )
            end
        # if it's the last token and ) --> link_ab_close
        elseif t.name == :BRACKET_CLOSE && i == n
            link_ab_close = t
        end
        i += 1
    end
    return (; link_a_open, link_a_close, link_ab_mid, link_ab_close, ref_mid)
end


"""
    _link_a(b, c; tohtml)

Handle a link of the form '[A]' (possibly '![A]'). First 'A' is extracted via
`_link_blocks` then the reference id is constructed and the converted 'A' is
formed, then the whole is passed to a function that will be evaluated at
second pass. This is necessary because the reference '[A]:' might be after
the placement of the link/img.
"""
function _link_a(b::Block, c::LocalContext; tohtml=true, img=false)
    ss = b.ss
    t  = _link_blocks(ss)
    t1 = t.link_a_open
    t2 = t.link_a_close

    title = subs(parent_string(ss), next_index(t1), prev_index(t2))
    ref   = string_to_anchor(title)
    title = convert_md(title, c; tohtml, nop=true)

    # XXX: with LaTeX context this will disappear, see latex2

    img && return """{{img_a $ref "$title"}}"""
    return """{{link_a $ref "$title"}}"""
end


"""
    _link_ab(b, c; tohtml)

Handle a link of the form '[A](B)' (possibly '![A](B)'). First 'A' and 'B' are
extracted via `_link_blocks` then the URI 'B' is normalized and the title 'A'
is converted and finally the link (or img) is formed.
"""
function _link_ab(b::Block, c::LocalContext; tohtml=true, img=false)
    ss = b.ss
    t  = _link_blocks(ss)
    t1 = t.link_a_open
    t2 = t.link_ab_mid
    t3 = t.link_ab_close

    title = subs(parent_string(ss), next_index(t1), prev_index(t2))
    title = convert_md(title, c; tohtml, nop=true)
    ref   = subs(parent_string(ss), next_index(t2), prev_index(t3))
    ref   = normalize_uri(ref)

    img && begin
        tohtml && return html_img(ref; alt=title)
        return """
            \\begin{figure}[!h]
                \\includegraphics[$(getvar(c, :latex_img_opts, "width=.5\\textwidth"))]{$ref}
                \\caption{$title}
            \\end{figure}
            """
    end

    tohtml && return html_a(title; href=ref)
    return "\\href{$ref}{$title}"
end


"""
[A]: B
"""
function _refref(b, c)
    ss = b.ss
    t  = _link_blocks(ss)
    t1 = t.link_a_open
    t2 = t.ref_mid

    ref_A = subs(parent_string(ss), next_index(t1), prev_index(t2))
    ref_A = string_to_anchor(ref_A)
    ref_B = strip(subs(parent_string(ss), next_index(t2), to(ss)))
    ref_B = normalize_uri(ref_B)

    refrefs_ = refrefs()
    refrefs_[ref_A] = ref_B
    return ""
end


html_link_a(b::Block, c::LocalContext)  = _link_a(b, c; tohtml=true)
latex_link_a(b::Block, c::LocalContext) = _link_a(b, c; tohtml=false)
html_img_a(b::Block, c::LocalContext)   = _link_a(b, c; tohtml=true, img=true)
latex_img_a(b::Block, c::LocalContext)  = _link_a(b, c; tohtml=false, img=true)

html_link_ab(b::Block, c::LocalContext)  = _link_ab(b, c; tohtml=true)
latex_link_ab(b::Block, c::LocalContext) = _link_ab(b, c; tohtml=false)
html_img_ab(b::Block, c::LocalContext)   = _link_ab(b, c; tohtml=true, img=true)
latex_img_ab(b::Block, c::LocalContext)  = _link_ab(b, c; tohtml=false, img=true)

# These can be in a global context!
html_ref(b::Block, c::Context)  = _refref(b, c)
latex_ref = html_ref

# autolink
html_autolink(b::Block, _)  = (c = content(b) |> string; html_a(c; href=c))
latex_autolink(b::Block, _) = (c = content(b) |> string; "\\href{$c}{$c}")
