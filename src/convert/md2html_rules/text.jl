# see https://github.com/MichaelHatherly/CommonMark.jl/issues/1#issuecomment-735990126)
struct SkipIndented end

block_rule(::SkipIndented) = CommonMark.Rule((p, c) -> 0, 8, "")

cm_parser = CommonMark.enable!(
                CommonMark.disable!(
                    CommonMark.Parser(),
                    CommonMark.IndentedCodeBlockRule()),
                SkipIndented())


function html(b::Block{:TEXT}, ::Context)
    # extract the content and inject HTML entities etc (see FranklinParser.prepare)
    s = prepare(b)
    return CommonMark.html(cm_parser(s))
end
