# Breaking changes

* `lx_fun` now take args as `hfuns` so `lx_foo(p::Vector{String})`
* `@def` do not accept multiline assignments anymore
* hard assumption of LF (i.e. end of lines are `\n` and not `\r\n`) (_LF Assumption_)


## Notes

* (**LF Assumption**) this could be relaxed, not sure how many people would have an issue; also for it to make sense would need to test on a windows box. To relax, update FranklinParser to have a token for `\r\n`, and update things with occurrences of `\n` (including the `process_line_return` function). Potentially having an editor with `\r\n` will not make things fail (since we'll capture the `\n`) but it's not tested.
