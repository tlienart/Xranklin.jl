#=
NOTE

IMPORTANT to understand the order.

1. MD parsing
2. gradual processing including solving of lxcoms (resolves lxfuns)
3. HTML2/LATEX2 postprocessing (resolves hfuns)

So lxfuns are resolved PRIOR to hfuns, and, for instance, can generate
a hfun so that that hfun takes the full context into account (this is
useful for forward references where you'd do \eqref{equation later} and
blah
$$ equation \label{equation later} $$

or biblabels etc.
=#


function lx_toc(; tohtml::Bool=true)
    if tohtml
        minlevel = getlvar(:mintoclevel)::Int
        maxlevel = getlvar(:maxtoclevel)::Int
        return "{{toc $minlevel $maxlevel}}"
    end
    # TODO could play with tocdepth setting, it won't be exactly the same
    return "\\tableofcontents"
end
lx_tableofcontents = lx_toc
