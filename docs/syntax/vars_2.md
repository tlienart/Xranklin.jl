+++
showtoc = true
header = "Page Variables (part 2)"
menu_title = header
+++

\label{hfuns}
## HTML functions and environments

By now you should already have an idea

* XXX functions can be used in Markdown no problem
* environments should only be used in HTML (their scope is not resolved in Markdown which so something like `{{for x in iter}} **{{x}}** {{end}}` will try to resolve `{{x}}` first, fail) (or within a raw HTML block)

### Default functions

### (XXX) Environments: conditionals

\showmd{
  +++
  flag = true
  +++

  {{if flag}}
  Hello
  {{else}}
  Not Hello
  {{end}}
}

\tip{
  While here the environment is demonstrated directly in Markdown, environments
  are best used in layout files (`_layout/...`) or raw HTML blocks and should, ideally,
  not be mixed with Markdown as the order in which elements are resolved by Franklin may not
  always be what you think and that can sometimes lead to unexpected results.

  This is even more true for loop environments introduced further below.
}

Naturally, you can have multiple branches with `{{elseif variable}}`. Here's another example

\showmd{
  +++
  flag_a = false
  flag_b = true
  +++

  {{if flag_a}}
  ABC
  {{elseif flag_b}}
  DEF
  {{end}}
}

There are some standard conditionals that can be particularly useful in layout.

| conditional | effect |
| ----------- | ------ |
| `{{ispage path}}` or `{{ispage path1 path2 ...}}` | checks whether the present page corresponds to a path or a list of paths, this can be particularly useful if you want to toggle different part of layout for different pages |
| `{{isdef var}}` | ... |

**etc** + check


### (XXX) Environments: loops

\showmd{
  +++
  some_list = ["bob", "alice", "emma", "joe"]
  +++

  {{for x in some_list}}
  {{x}} \\
  {{end}}
}

\showmd{
  +++
  iter = ["ab", "cd", "ef"]
  +++

  {{for e in iter}}
  _value_ ? **{{e}}**\\
  {{end}}
}

\tip{
  The example above shows mixing of Markdown inside the scope of the loop environment,
  here things are simple and work as expected but as indicated in the previous tip,
  you should generally keep environments for HTML blocks or layout files.
}


### E-strings

E-strings allow you to run simple Julia code to define the parameters of a `{{...}}` block.
This can be useful to

1. insert some value derived from some page variables easily,
1. have a conditional or a loop environment depend on a derivative of some page variables.

The first case is best illustrated with a simple example:

\showmd{
  +++
  foo = 123
  +++

  * {{e"1+1"}}
  * {{e"$foo"}} you can refer to page variables using `$name_of_variable`
  * {{e"$foo^2"}}
  * {{e"round(sqrt($foo), digits=1)"}}
}

More generally the syntax is `{{ e"..." }}` where the `...` is valid Julia code
where page variables are prefixed with a `$`.
The alternative syntax `{{> ...}}` is also supported:

\showmd{
  +++
  bbb = 321
  +++

  {{> $bbb // 3}}
}

The code in the e-string is evaluated inside the [utils module](/syntax/utils/)
and so could leverage any package it imports or any function it defines.
For instance we added a function

```julia
bar(x) = "hello from foo <$x>"
```

to `utils.jl` and can call it from here in an e-string as:

\showmd{
  {{e"bar($foo)"}}
}

As noted earlier, these e-strings can also be useful for conditional and loop environments:

* `{{if e"..."}}`
* `{{for ... in e"..."}}`

For the first, let's consider the case where you'd like to have some part of your layout
depend on whether either one of two page variables is true.
For this you can use an e-string and write `{{if e"$flag1 || $flag2"}}`:

\showmd{
  +++
  flag1 = false
  flag2 = true
  +++
  {{if e"$flag1 || $flag2"}}
  Hello
  {{else}}
  Not Hello
  {{end}}
}

More generally you can use an e-string for any kind of condition written in Julia
as long as it evaluates to a boolean value (`true` or `false`).

For loop environments, you can likewise use an e-string that would give you some
derived iterator that you'd wish to go over:

\showmd{
  +++
  iter1 = [1, 2, 3]
  iter2 = ["abc", "def", "ghi"]
  +++
  ~~~
  <ul>
  {{for (x, y) in e"zip($iter1, $iter2)"}}
  <li><strong>{{x}}</strong>: <code>{{y}}</code></li>
  {{end}}
  </ul>
  ~~~
}

### More customisation

If the default functions and environments, possibly coupled with e-strings are
not enough for your use case or are starting to feel a bit clunky, it's time
to move on to [writing custom hfuns](/syntax/utils/).

This approach allows you to write `{{your_function p1 p2 ...}}` where
`your_function` maps to a Julia function that you define and that produces a
string based on whatever logic that would be appropriate for your use case.
