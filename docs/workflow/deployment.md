+++
showtoc = true
header = "Deploying a Website"
menu_title = "Deployment"
+++

[url_action]: https://github.com/tlienart/xranklin-build-action
[url_x_action]: https://github.com/tlienart/Xranklin.jl/.github/workflows/deploy.yml

\label{howto prepath}

## Overview

When calling `serve()` locally, your website is generated and the corresponding files are placed in the folder `__site` (e.g. you will find `__site/index.html` which corresponds to your site's landing page). 

To deploy your site, we have to place the content of this `__site` folder somewhere appropriate after fixing relative paths. Consider the following two scenarios:

1. you want your landing page to correspond to `https://www.foo.bar/`,
2. you want your landing page to correspond to `https://www.foo.bar/abc/`.

In the first case, the setting is the same as your local setting except your local setting uses something like `https://localhost:8000/`.
In this context there is no need to change anything.

In the second case, the setting is not the same, there is a _prefix_ (`abc`) which must be taken into account to guarantee all your relative links will work.

If you intend to use GitHub to deploy your site, the GitHub action will take care of almost everything, you will only have to specify the prefix.
If you intend to use another approach there is two steps to deploy your site:

1. call `build` which will generate `__site` and fix the links according to the provided prefix,
2. place the generated content of `__site` somewhere where it can be seen by others.


### Setting the base URL prefix

The easiest is to specify the prefix in your `config.md` by specifying `base_url_prefix` or `prefix` to the correct string:

```
base_url_prefix = "abc"
```

Alternatively you can specify that as a keyword to the `build` command:

```
build(base_url_prefix="abc")
```

Lastly, if you want to use GitHub for deployment, you can also specify the prefix in the GitHub Action's `with` parameters:

```yml
    ...
    with:
        BASE_URL_PREFIX: "abc"
        ...
```

\note{
    The prefix can be made of several parts, `abc/def` is allowed for instance.
}

## Deployment with GitHub

It is very convenient to use GitHub to deploy your site, and so we add details for that specific case.

### Prefix on GitHub

There are three possible scenarios on GitHub:

1. the repo is `username.github.io` in which case your site will be available at `https://username.github.io`, no prefix.
2. the repo is `someRepo` in which case your site will be available at `https://username.github.io/someRepo/`, prefix should be `"someRepo"`.
3. you want a deployment on a custom URL, set the prefix if you want the landing page to be elsewhere than the root e.g. for `www.yourURL.com/blah/` set the prefix to `"blah"`.

In short, you have to be mindful of what the prefix is and indicate it to Franklin.

### Using the GitHub action

On GitHub there's a [dedicated action][url_action] that you can use to deploy your site.
This is by far the easiest approach to deploying your website.

In order to use it, create a `.github/workflows/deploy.yml` file in your repo and adjust the following blueprint as needed:

```yml
name: Build and Deploy
on:
  push:
    branches:
      - main

jobs:
  docs:
    runs-on: ubuntu-latest
    permissions: write-all
    steps:
      - uses: actions/checkout@v3

      - name: 🚀 Build and Deploy
        uses: tlienart/xranklin-build-action@main
        with:
          BASE_URL_PREFIX: "abc"
```

You could choose to extend this quite a lot e.g. if you want PRs to the repo to deploy to a dedicated URLs as [done here][url_x_action].

## Deployment with GitLab

On GitLab you will just need to have a `.gitlab-ci.yml` script which 

1. calls `build`,
2. places `__site` to `public`

something like the following:

```yml
image: julia:1.8

pages:
  stage: deploy
  script:
    - julia --project=@. -e '
        import Pkg;
        Pkg.add("Franklin");
        using Franklin;
        build(prefix="abc");'
    - mv __site public
  artifacts:
    paths:
      - public
  only:
    - main
```

## Manual deployment

If you want to deploy things yourself or use some other platform than GitHub or GitLab to do it, you will have to:

1. call `build(prefix="...")` for instance locally (possibly remotely if you're using a platform that can run code),
2. move the content of `__site` somewhere where it can be seen by others.

The GitLab case above should hopefully provide a useful blueprint for this.