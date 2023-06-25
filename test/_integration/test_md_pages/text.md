# TEXT

## H2
### H3

## Basics

L> Bold, italic: A **B** C _D_ E _**F**_

L> Line break \\ and `inline code`.

L> Entities: \{&#42; &reg; &plusmn;\} and emojis 👎 and also :+1: but :foo: (emojis are not rendered in the LaTeX case).

L> Escaped chars: \{ \} \* \_ \`

Hrule:
---

## Lists

**Unordered**

* item a
* item b
* item c

**Ordered**

1. item a
1. item b
1. item c

**Nested** (nesting must be sufficiently indented)

* item a
  * subitem a.a
    * subsubitem a.a
  * subitem a.b
* item b

**Mixed nesting**

* item a
  * subitem a.a
    1. subsubitem a.a
    1. subsubitem a.b
  * subitem a.b
* item b

## Links

* external: [franklinjl docs](https://franklinjl.org)
* internal: [vars](/vars.html)

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
