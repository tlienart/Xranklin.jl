+++
tags = ["tag 1", "tag 2"]
item_list = [
  "* item number $i\n"
  for i in 1:10
]
+++

# Page 2

* [Landing page](## landing page)


## Pagination

{{paginate item_list 5}}

on {{ispage /page2/}}[the next page](/page2/2/){{else}}[the previous page](/page2/){{end}} you'll see the rest of the items

Seems ok.
