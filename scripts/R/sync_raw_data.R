#!/usr/bin/env Rscript
# Sync a chapter's raw source data from Azure Blob -----------------------------
#
# Command-line wrapper around refresh_raw_chapter_data(). Run this before
# editing or rendering a chapter you did not author, so you work from the
# current central data. Rendering never calls it - the download is a deliberate,
# manual step (see WIP/azure-migrate/analyst-setup.md).
#
# Usage:
#
#     Rscript scripts/R/sync_raw_data.R <chapter> [<chapter> ...]
#
# Examples:
#
#     Rscript scripts/R/sync_raw_data.R 05-environment
#     Rscript scripts/R/sync_raw_data.R 02-transport 05-environment
#
# VPN MUST BE ON. The first sync in a while prompts an Entra ID sign-in.
# =============================================================================

chapters <- commandArgs(trailingOnly = TRUE)

if (length(chapters) == 0L) {
  stop(
    "Usage: Rscript scripts/R/sync_raw_data.R <chapter> [<chapter> ...]\n",
    "  e.g. Rscript scripts/R/sync_raw_data.R 05-environment",
    call. = FALSE
  )
}

source(here::here("scripts", "R", "azure_blob.R"))

# Authenticate once, then reuse the container for every requested chapter.
cont <- weca_blob_container()

purrr::walk(chapters, \(chapter) {
  refresh_raw_chapter_data(chapter, cont = cont)
})
