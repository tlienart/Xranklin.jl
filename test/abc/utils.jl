import Literate
import UnicodePlots

function html_show(p::UnicodePlots.Plot)
    td = tempdir()
    tf = tempname(td)
    io = IOBuffer()
    UnicodePlots.savefig(p, tf; color=true)
    # assume ansi2html is available
    if success(pipeline(`cat $tf`, `ansi2html -i -l`, io))
        return "<pre>" * String(take!(io)) * "</pre>"
    end
    return ""
end
