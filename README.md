# coding 101

[![Netlify Status](https://api.netlify.com/api/v1/badges/f891cc91-4c06-47f5-8cb7-ff4a24df2fe2/deploy-status)](https://app.netlify.com/sites/confident-dubinsky-6917c9/deploys)

My notes on programming, mostly using R, Python, and bash.

### Using mkdocs

This site is built using [MkDocs](https://www.mkdocs.org). It uses [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) theme and several extensions. To build local version of this documentation, you can install/upgrade following python packages, preferably in clean conda or virtual env. You can then use scripts similar to [serve_docs.sh] and [push_docs.sh] to serve and optionally, host your own documentation on Github Pages.

```
pip install --upgrade mkdocs mkdocs-material mkdocs-git-revision-date-plugin  mkdocs-git-revision-date-localized-plugin mkdocs-minify-plugin pymdown-extensions mkdocs-macros-plugin mike
```
