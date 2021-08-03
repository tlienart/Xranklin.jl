html_md_def(b, c)  = (add_vars!(c, content(b)); "")
latex_md_def(b, c) = (add_vars!(c, content(b)); "")
html_md_def_block  = html_md_def
latex_md_def_block = latex_md_def
