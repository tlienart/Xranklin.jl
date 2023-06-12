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

As indicated earlier, the output of an lxfun gets process_file_from_triggered at the second pass, so
for instance:

```julia
function lx_exlx3()
    # fill the local variable header
    return "<span style='color:blue'>{{header}}</span>"
end
```

and if we call `\exlx3` we get: \exlx3.


### Custom envfuns



### Custom hfuns


## Utils tools

When defining any function in utils, you can make use of a set of useful functions available by default:

| function | description |
| :--- | :--- |
| `html(s)`,\\ `html(s, lc)` | convert a markdown string `s` (optionally specifying the `LocalContext` object in which this should happen) |
| `cur_gc()` | return the current `GlobalContext` object |
| `cur_lc()` | return the current `LocalContext` object |
| `path(s)` | return the path associated with symbol `s` for instance `path(:folder)` will return the path to the website folder, `path(:site)` the path to the output folder. |
| `getlvar(s)` | value of the local var with symbol `s` |
| `getgvar(s)` | value of the global var with symbol `s` |
| `getvarfrom(s, rp)` | value of the local var with symbol `s` expected to be defined on page with relative path `rp` |
| `setlvar!(s, v)` | set the value of a local var with symbol `s` to `v` |
| `setgvar!(s, v)` | set the value of a global var with symbol `s` to `v` |
| `get_page_tags(rp)` | get all the tags defined on the current page or, if `rp` is specified, on the page corresponding to `rp` |
| `get_all_tags()` | get the dictionary of all tags on all pages |
| `get_rpath` | get the relative path to the current page |
