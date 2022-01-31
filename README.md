# Xranklin

[![CI Actions Status](https://github.com/tlienart/Xranklin.jl/workflows/CI/badge.svg)](https://github.com/tlienart/Xranklin.jl/actions)
[![codecov](https://codecov.io/gh/tlienart/Xranklin.jl/branch/main/graph/badge.svg?token=7gUn1zIEXw)](https://codecov.io/gh/tlienart/Xranklin.jl)

## About

This repo contains the code for the next minor (and, once properly tested, major) version of
[Franklin.jl](https://github.com/tlienart/Franklin.jl).
The code has basically been written from scratch and your help is needed to uncover bugs and
problems.

Most of what's offered by Franklin is also offered by Xranklin (apart from what's listed in [this issue](https://github.com/tlienart/Xranklin.jl/issues/65) which we should make as precise as possible).

[**Link to the new docs**](https://tlienart.github.io/Xranklin.jl/) (under active construction).

## How to help test this?

**Assumptions**:
* you're familiar with Franklin and already have a website repo that works,
* you're using GitHub and GitHub deployment (if not, it's also great, but you'll be more on your own for now),
* you're using Julia 1.6+
* your editor uses LF (lines end with `\n`, this is only a concern for you if you're on Windows but if you use a modern editor, it should be the default or easy to set)

Here's a suggested workflow:

1. duplicate an existing Franklin-repo and give me collaborator access to that duplicated repo (to speed up debugging),
2. clone the repo locally, and add `Xranklin` to your environment with `Pkg.add(url="https://github.com/tlienart/Xranklin.jl", rev="main");`
3. `cd` to the repo and do `using Xranklin; serve(debug=true)`, this will generate a lot of output,
4. if you have errors, check the migration points below to see if the error can be quickly fixed, if not, open an issue
   * indicate your OS, Julia version, link to the repo and to the commit that failed if not the latest
   * indicate the patch version of Xranklin,
   * copy paste the error and previous few lines in the issue,
5. assuming things work locally, test the deployment
   * make sure you adjust `prepath` in `config.md`
   * create or change the `.github/workflows/deploy.yml` to the script below
   * check if it deploys successfully (check in the repo settings that `Pages` consume `gh-pages`)
6. thoughts, feedback, open an issue
7. thanks a lot!!

<details>
  <summary>Click here to expand the github deploy script</summary>

```yaml
name: Build and Deploy
on:
  push:
    branches:
      - main
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Git checkout
        uses: actions/checkout@v2

      - name: Cache
        uses: actions/cache@v2
        with:
          path: |
                __cache
                ~/.julia
          key: ${{ runner.os }}-franklin-cache-${{ github.sha }}
          restore-keys: ${{ runner.os }}-franklin-cache-

      # Julia
      - name: Install Julia
        uses: julia-actions/setup-julia@v1
        with:
          version: 1.7

      # Website build
      - run: julia -e '
          using Pkg; Pkg.add(url="https://github.com/tlienart/Xranklin.jl", rev="main");
          using Xranklin; build();'

      # Deployment and caching
      - run: touch __site/.nojekyll
      - name: Deploy 🚀
        uses: JamesIves/github-pages-deploy-action@releases/v4
        with:
          BRANCH: gh-pages
          FOLDER: __site
```
</details>


## Migration notes

[**Link to the new docs**](https://tlienart.github.io/Xranklin.jl/), the docs are being built so expect rough edges but if you find things that can be added or explained better, please open issues. Don't worry too much about layout issues for now.

**Changes**:

* page variable definitions, move from `@def x = ...` to `+++ ... +++` blocks (see [docs](https://tlienart.github.io/Xranklin.jl/syntax/vars+funs/)), `@def` will still work but will not allow multi-line assignments, generally `+++...+++` are preferred now
* `@delay` is removed (it's not required anymore)
* `lxfuns` now take arguments as `hfuns` (a list of parameters corresponding to the braces) see [this example](https://github.com/tlienart/Xranklin.jl/blob/3eb0ce295f0505a7c0519558392d95c2e72fa52d/src/convert/markdown/lxfuns/misc.jl#L1-L11)
* `envfuns` now take arguments differently, see [this example](https://github.com/tlienart/Xranklin.jl/blob/3eb0ce295f0505a7c0519558392d95c2e72fa52d/src/convert/markdown/envfuns/math.jl#L20-L29)

This has not yet been migrated and so you shouldn't expect it to work (see also [this issue](https://github.com/tlienart/Xranklin.jl/issues/65))

* RSS generation
* sitemap generation
* robots generation
* slug
* lunr

---

## Dev Notes

### Breaking changes from Franklin

* `lx_fun` now take args as `hfuns` so `lx_foo(p::Vector{String})`
* `@def` do not accept multiline assignments anymore, generally prefer `+++...+++` blocks
* hard assumption of LF (i.e. end of lines are `\n` and not `\r\n`) (_LF Assumption_)

**Notes**
* (**LF Assumption**) this could be relaxed, not sure how many people would have an issue;
also for it to make sense would need to test on a windows box.
To relax, update `FranklinParser` to have a token for `\r\n`, and update things with occurrences
of `\n` (including the `process_line_return` function). Potentially having an editor with `\r\n`
will not make things fail (since we'll capture the `\n`) but it's not tested.

### LaTeX

* hyperrefs
* booktabs (for tables)
* csquotes (for blockquotes)
