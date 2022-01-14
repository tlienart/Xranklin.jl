+++
header = "foo"
+++

\newcommand{\pycode}[2]{
  ```:_py-#1
  #hideall
  using PyCall
  lines = replace(
    """#2""",
    r"(^|\n)([^\n]+)\n?$" => s"\1res = \2"
  )
  py"""
  $$lines
  """
  println(py"res")
  ```
  ```python
  #2
  ```
  \show{_py-#1}
}

\pycode{ex1}{
  import numpy as np
  np.random.seed(2)
  x = np.random.randn(5)
  r = np.linalg.norm(x) / len(x)
  np.round(r, 2)
}
