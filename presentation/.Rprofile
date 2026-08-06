# Activate the parent project's renv library. R only reads .Rprofile from
# the exact working directory it starts in, not parent directories, so
# `quarto render` run with working-directory: presentation needs its own
# copy of this logic to pick up the same renv library as the book render.
#
# renv/activate.R falls back to getwd() when RENV_PROJECT is unset, which
# would bootstrap a brand-new, empty renv project rooted at presentation/
# instead of reusing the root project's library. Point it at the root
# explicitly first.
Sys.setenv(RENV_PROJECT = normalizePath(".."))
source("../renv/activate.R")
