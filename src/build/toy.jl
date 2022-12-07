"""
    toy_example(name="toy_example")

Generate a basic folder that can be used for quick testing
in the current directory.

## KW-Args

    name    : name of the toy directory, assumed not to clash
              with an existing directory

"""
function toy_example(;
            name::String="toy_example"
        )::Nothing

    if isdir(name)
        @warn """
            toy example
            A directory named '$name' already exists. Remove it
            or change the name when calling toy_example.
            """
        return
    end
    parent = name
    mkdir(parent)

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
        </head>
        <body>
            {{page_content}}
        </body>
        </html>
        """)

    write(parent / "config.md", raw"""
        +++
        using Dates

        author = "Kathleen Booth"
        thedate = Date(1947, 9, 19)

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
        - Reference to global variagble: '{{author}}'

        ## Simple code

        ```!
        x = 5
        mod(x^3, 2)
        ```

        ## Simple command

        This will be in \css{color: red; font-weight: 500;}{red}.
        """)

    @info """
        The toy folder is available at '$parent', you can try it by
        running the following command:

            serve("$parent")
        """
    return
end
