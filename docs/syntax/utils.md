+++
showtoc = true
header = "Defining HTML functions and LaTeX commands with code"
menu_title = "Utils"
table_class = "pure-table-striped"
+++

~~~
<style>
.pure-table-striped td { padding: .75em;}
</style>
~~~

## Overview

Along with the `config.md` file, the `utils.jl` file allows you to define functions and objects that may be useful throughout your website and, also, to define special functions that you can call on pages.
In `utils.jl` you can:

1. define objects and functions that can be accessed from any code cell via the `Utils` module,
1. define your own `html_show(obj::SomeType)` for objects of `SomeType` which should be shown in a specific way when returned by executed cells,
1. define functions with specific signatures to power custom commands, environments or html functions.

The first two are pretty simple and explained in the two short subpoints below.
The last point is a bit more involved and is discussed with examples in the [custom functions](## custom functions) section below.

### Definining objects and functions in the `Utils` module

The code in `utils.jl` is made available via a `Utils` module that can be accessed from any code cell.
For instance, in the `utils.jl` of the present website, we have the code

```julia
struct Baz
    z::Int
end

newbaz(z) = Baz(z)
```

This can be accessed on the current page (or any other page) via the `Utils` module:

```!
b = Utils.Baz(1)
@show b.z
b2 = Utils.newbaz(3)
@show b2.z
```

### Custom show method

When showing the output of a code cell, a custom show method can be defined in Utils
to be called for specific objects.
The signature of that method must be `html_show(obj::SomeType)`.

For instance, in the `utils.jl` we have:

```julia
struct Foo
    x::Int
end
html_show(f::Foo) = "<strong>Foo: $(f.x)</strong>"
```

the custom show gets called when the resulting object of an executed code block
is of the type (here `Foo`):

```!
Utils.Foo(1)
```

see also [this point](##custom_show) for more information on custom show methods.


## Custom functions

Functions defined in utils with a name that start with `lx_fname`, `env_fname` or `hfun_fname` can be called on pages respectively with `\fname{...}`, `\begin{fname}...\end{fname}` and `{{fname ...}}`.
This allows you to essentially have arbitrary logic executed at page-build time.

Before clarifying how these functions should be defined and called, it is useful to remember the order in which such commands will be resolved:

* `lx*` and `env*` functions will be resolved on **first pass**, as soon as they're seen by Franklin. The context that is available to these functions, correspondingly, is whatever was processed before them. These functions are expected to return "intermediate" HTML (i.e. possibly containing `{{...}}`) and will be further processed in a second pass.
* `hfun*` functions will be resolved on **second pass**, as such they have access to the full page context, and are expected to produce "final" HTML.

In many cases, the differences are irrelevant, and users can use whichever they prefer.


### Custom hfuns

The signature of a valid "hfun" is:

```julia
function hfun_fname(p::Vector{String})::String
    # logic
    return "..."
end
```

Of course you don't _have_ to add the explicit typing, but we added it here to
indicate that these functions map a vector of strings (arguments) to a string
output to be inserted.

Once such a function is defined, it can be called on any page (including layout
pages) with `{{fname ...}}`.

Here are three simple examples:

```julia
function hfun_ex_hfun_1()
    return "<span style=\"color:red; font-weight: 500;\">Hello!</span>"
end

function hfun_ex_hfun_2(p)
    return "<span style=\"color:red; font-weight: 500;\">$(strip(p[1], '\"'))</span>"
end

function hfun_ex_hfun_args(p)
    io = IOBuffer()
    for (i, p_i) in p
        println(io, "* argument $i: \"$(p_i)\"")
    end
    return html(String(take!(io)))
end
```

The first one (`hfun_ex_hfun_1`) doesn't have arguments and just prints a coloured span:

\showmd{
    Called like: {{ ex_hfun_1 }}
}

The second one (`hfun_ex_hfun_2`) assumes there's one argument and prints it:

\showmd{
    Called like: {{ ex_hfun_2 "Hello World!"}}
}

\note{
    You might want to add logic in these `hfun` to check that the input arguments match some constraints. This may not be very useful if you're the only one defining and using these functions, but it might become so if you start collaborating on the website with others.
}

The last one (`hfun_ex_hfun_args`) is meant to illustrate how the argument splitting works:

\showmd{
    Hopefully this is intuitive: {{ex_hfun_args abc "def ghi" 123}}
}

At this point you probably already have the intution for the argument splitting: the arguments
are assumed to be separated by one or more spaces unless they are grouped with quotes.
Any quotes are passed to the function and, depending on your use case, you may want to strip them
with `strip(p[k], '\"')` as we did in `hfun_ex_hfun_2`.

When defining a "hfun", you can interact with the state of the website through a few
functions that are available in the Utils module, see [Utils tools](#utils_tools).

### Custom lxfuns

The signature of a valid "lxfun" is

```julia
function lx_fname(p::Vector{String})::String
    # logic
    return "..."
end
```

where `fname` can be switched for anything command name you want and where the
argument (`p` here) is a list of strings corresponding to each of the brace that will
be given to the command.
It can be left empty in the definition if the user desires to have an argument-less command.

Here's an example:

```julia
function lx_exlx(p::Vector{String})
    return "<i>$(uppercase(p[1]))</i> <b>$(uppercasefirst(p[2]))</b>"
end
```

and if we call `\exlx{hello}{reader}`, we get: \exlx{hello}{reader}.

Here's another example without arguments:

```julia
function lx_exlx2()
    return "<s>hello</s>"
end
```

and if we call `\exlx2` we get: \exlx2.

As indicated earlier, the output of an lxfun gets `process_file_from_triggered` at the second pass, so
for instance:

```julia
function lx_exlx3()
    # fill the local variable header
    return "<span style='color:blue'>{{header}}</span>"
end
```

and if we call `\exlx3` we get: \exlx3.


### Custom envfuns


## Utils tools

When defining any function in utils, you can make use of a set of useful functions available by default,
and which allow you to interact with the state of the website generation process.

| function | description |
| :--- | :--- |
| `html(s)`,\\ `html(s, lc)` | convert a markdown string `s` (optionally specifying the `LocalContext` object in which this should happen) |
| `html2(s)`, \\`html2(s, lc)` | convert an intermediate HTML string (essentially: finds and processes `{{...}}`) |
| `cur_gc()` | return the current `GlobalContext` object |
| `cur_lc()` | return the current `LocalContext` object |
| `path(s)` | return the absolute path associated with symbol `s` for instance `path(:folder)` will return the path to the website folder, `path(:site)` the path to the output folder. |
| `getlvar(s)` | value of the local var with symbol `s` |
| `getgvar(s)` | value of the global var with symbol `s` |
| `getvarfrom(s, rp)` | value of the local var with symbol `s` expected to be defined on page with relative path `rp` |
| `setlvar!(s, v)` | set the value of a local var with symbol `s` to `v` |
| `setgvar!(s, v)` | set the value of a global var with symbol `s` to `v` |
| `get_page_tags(rp)` | get all the tags defined on the current page or, if `rp` is specified, on the page corresponding to `rp` |
| `get_all_tags()` | get the dictionary of all tags on all pages |
| `get_rpath()` | get the relative path to the current page |
| `attach(rp)` | attach a file at `rp` to the current page (see [below](#attaching_a_file)) |



### Attaching a file

The `attach` tool is necessary to indicate that a page **depends** on another file (e.g. a script, data, ...) which, if changed, should trigger a re-build of the page.

To give a concrete example: this is used for the built-in handling of Literate files. If a page depends on a Literate file, then any change on that Literate file should trigger a re-build of that page.
