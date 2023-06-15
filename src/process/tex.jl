# ------------------- #
# TEX FILE PROCESSING #
# ------------------- #

# (should be the same as HTML)


# """
#     _process_md_file_latex
#
# """
# function _process_md_file_latex(
#             lc::LocalContext,
#             page_content_md::String;
#             skip=false
#         )
#
#     page_content_latex = getvar(lc, :_generated_latex, "")
#     if !skip || isempty(page_content_latex)
#         page_content_latex = latex(page_content_md, lc)
#         setvar!(lc, :_generated_latex, page_content_latex)
#     end
#
#     full_page_latex = raw"\begin{document}" * "\n\n"
#     head_path = path(:layout) / getvar(lc.glob, :layout_head_lx)::String
#     if !isempty(head_path) && isfile(head_path)
#         full_page_latex = read(head_path, String)
#     end
#     full_page_latex *= page_content_latex
#     full_page_latex *= "\n\n" * raw"\end{document}"
#
#     return full_page_latex
# end
