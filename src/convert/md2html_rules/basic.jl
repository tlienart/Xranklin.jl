
html(b::Block{:COMMENT},  ::Context) = ""
html(b::Block{:RAW_HTML}, ::Context) = content(b)



function html(b::Block{:DIV}, ctx::Context)
    classes = get_classes(b)
    inner   = html(default_md_partition(b), ctx)
    return """
        <div class="$classes">
          $inner
        </div>
        """
end
