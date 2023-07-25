"""
    toy_example(name="toy_example")

Generate a basic folder that can be used for quick testing
in the current directory.

## KW-Args

    name    : name of the toy directory, assumed not to clash
              with an existing directory

"""
function toy_example(;
            name::String="toy_example",
            parent::String="",
            silent::Bool=false
        )::String

    if !isempty(parent)
        name = parent / name
    end
    
    if isdir(name)
        @warn """
            toy example
            A directory named '$name' already exists. Remove it
            or change the name when calling toy_example.
            """
        return name
    end
    parent = name
    mkpath(parent)

    layout = parent / "_layout"
    mkdir(layout)
    write(layout / "skeleton.html",
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport"
                content="width=device-width, initial-scale=1.0">
          <link rel="stylesheet"
                href="https://cdn.jsdelivr.net/npm/water.css@2/out/light.css">
          <!-- ansicoloredprinters ; check _form_code_repr -->  
          <style>
          span.sgr1 {font-weight: bolder;}span.sgr2 {font-weight: lighter;}span.sgr3 {font-style: italic;}span.sgr4 {text-decoration: underline;}span.sgr7 {color: #fff;background-color: #222;}span.sgr8, span.sgr8 span, span span.sgr8 {color: transparent;}span.sgr9 {text-decoration: line-through;}span.sgr30 {color: #111;}span.sgr31 {color: #944;}span.sgr32 {color: #073;}span.sgr33 {color: #870;}span.sgr34 {color: #15a;}span.sgr35 {color: #94a;}span.sgr36 {color: #08a;}span.sgr37 {color: #ddd;}span.sgr40 {background-color: #111;}span.sgr41 {background-color: #944;}span.sgr42 {background-color: #073;}span.sgr43 {background-color: #870;}span.sgr44 {background-color: #15a;}span.sgr45 {background-color: #94a;}span.sgr46 {background-color: #08a;}span.sgr47 {background-color: #ddd;}span.sgr90 {color: #888;}span.sgr91 {color: #d57;}span.sgr92 {color: #2a5;}span.sgr93 {color: #d94;}span.sgr94 {color: #08d;}span.sgr95 {color: #b8d;}span.sgr96 {color: #0bc;}span.sgr97 {color: #eee;}span.sgr100 {background-color: #888;}span.sgr101 {background-color: #d57;}span.sgr102 {background-color: #2a5;}span.sgr103 {background-color: #d94;}span.sgr104 {background-color: #08d;}span.sgr105 {background-color: #b8d;}span.sgr106 {background-color: #0bc;}span.sgr107 {background-color: #eee;}
          </style>
        </head>
        <body>
            {{page_content}}
        </body>
        </html>
        """)

    write(parent / "config.md", raw"""
        +++
        author = "Kathleen Booth"
        thedate = Dates.Date(1947, 9, 19)

        +++

        \newcommand{\css}[2]{~~~<span style="#1">~~~#2~~~</span>~~~}
        """)

    write(parent / "index.md", raw"""
        +++
        somevar = 52
        +++

        # Test Page

        Some text here etc

        ## References

        - Reference to local variable: '{{somevar}}'
        - Reference to global variable: '{{author}}'

        ## Simple code

        ```!
        x = 5
        mod(x^3, 2)
        ```

        ## Simple command

        This will be in \css{color: red; font-weight: 500;}{red}.
        """)

    silent || @info """
        The toy folder is available at '$parent', you can try it by
        running the following command:

            serve("$parent")
        """
    return parent
end
