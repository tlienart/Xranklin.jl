# Test page (basics)

<!-- ============================================================ -->
## TEXT

L> Bold, italic: A **B** C _D_ E _**F**_

L> Line break \\ and `inline code`.

L> Entities: \{&#42; &reg; &plusmn;\} and emojis 👎 and also :+1: but :foo: (emojis are not rendered in the LaTeX case).

L> Escaped chars: \{ \} \* \_ \`

---

### Raw HTML

In LaTeX nothing will show here

~~~
<span style="color: blue">Hello in blue</span>
~~~

### Div

(In LaTeX just the text will show)

~~~
<style>
.da {
  background-color: lemonchiffon;
  padding: 15px;
}
.db {
  font-size: larger;
  color: navy;
}
</style>
~~~

@@da,db
Hello friend (HTML: in yellow)
@@

<!-- ============================================================ -->
## COMMANDS

### Without arguments

\newcommand{\foo}{bar}

Command `\foo`: \foo;

### With arguments

\newcommand{\fooz}[1]{bar:#1}

Command `\fooz{abc!}`: \fooz{abc!}.


<!-- ============================================================ -->
## ENVIRONMENTS
**TODO**

<!-- ============================================================ -->
## MATHS

### Basic inline maths

Some maths: $\alpha + \beta = 5\abeta$.

### With commands

\newcommand{\abeta}{\alpha\beta}
\newcommand{\scal}[1]{\left\langle #1\right\rangle}

$$
  \scal{x, \sum_{i=1}^n y_i} = \abeta
$$

### Environments
**TODO**

<!-- ============================================================ -->
## CODE
**TODO**

### Inline code

Hello `abc` and `def \ < > ghi`.

### Basic code

```
block plaintext
  indented line <b>hello</b>
more code
```

```
  (ind) more complicated
not indented
```

### Code with language

```julia
println("Hello!")
x = @. randn(5) + 2
y = norm(x)
struct Foo <: Bar
  a::Int
end
```

<!-- ============================================================ -->
## VARIABLES
**TODO**


<!-- ============================================================ -->
## HFUN
**TODO**


<!-- ============================================================ -->
## LXFUN
**TODO**

<!-- ```julia
println("Hello!")
``` -->

<!-- ## Lists

Unordered

- A
- B
- C

Ordered

1. A
1. B
1. C -->
