# Azure Blob helpers for WECA regional indicators -----------------------------
#
# Sources a chapter's raw data from the central Azure Blob container so any
# analyst can re-render any chapter, independently of who authored it. The blob
# is the single source of truth; local `data/raw/` is a disposable cache.
#
# Authentication is via Entra ID (your WECA login + MFA) using a device-code
# flow - there is no shared secret. The first sync in a session prompts you to
# sign in at https://microsoft.com/devicelogin; the token is then cached and
# refreshed silently by AzureAuth for subsequent syncs.
#
# The blob layout mirrors the local layout exactly:
#
#     data/raw/{chapter}/...   (in the container)
#     data/raw/{chapter}/...   (on your machine)
#
# so a downloaded blob's name is also its local path - no mapping required.
#
# =============================================================================
# CONFIGURATION (.env at repo root - git-ignored, all values non-secret)
# =============================================================================
#
#     AZURE_TENANT_ID=<tenant-guid>
#     AZURE_CLIENT_ID=<app-registration-client-id>
#     STORAGE_ACCOUNT_URL=https://wecasadwcorpdev.blob.core.windows.net
#     CONTAINER=analysis-landingzone
#
# =============================================================================
# TYPICAL USE
# =============================================================================
#
#   source(here::here("scripts", "R", "azure_blob.R"))
#   refresh_raw_chapter_data("05-environment")   # download into data/raw/
#
# or from the command line (see scripts/R/sync_raw_data.R):
#
#   Rscript scripts/R/sync_raw_data.R 05-environment
#
# VPN MUST BE ON for any blob operation - the storage account is firewalled to
# the WECA network. A VPN failure surfaces as a timeout, not an auth error.
# =============================================================================

library(AzureStor)
library(AzureAuth)
library(dplyr)
library(purrr)
library(fs)
library(glue)

#' Authenticate to the WECA blob container via Entra ID
#'
#' Builds an [AzureStor::blob_container()] object authenticated with the current
#' analyst's Entra ID identity (device-code flow, MFA on first use). Reads the
#' non-secret connection settings from `data/.env`. The returned container is the
#' handle passed to every other function in this file.
#'
#' The underlying OAuth token is cached on disc by `AzureAuth` (under
#' `AppData/Local/AzureR` on Windows) and refreshed silently, so only the first
#' call in a while triggers an interactive sign-in.
#'
#' @param account_url Blob endpoint URL. Defaults to the `STORAGE_ACCOUNT_URL`
#'   environment variable.
#' @param container Container name. Defaults to the `CONTAINER` environment
#'   variable.
#' @param tenant Entra tenant (directory) ID. Defaults to `AZURE_TENANT_ID`.
#' @param app App registration (client) ID. Defaults to `AZURE_CLIENT_ID`.
#'
#' @return An `AzureStor` blob container object.
#'
#' @examples
#' \dontrun{
#' cont <- weca_blob_container()
#' AzureStor::list_storage_files(cont, dir = "data/raw/05-environment")
#' }
weca_blob_container <- function(account_url = Sys.getenv("STORAGE_ACCOUNT_URL"),
                                container = Sys.getenv("CONTAINER"),
                                tenant = Sys.getenv("AZURE_TENANT_ID"),
                                app = Sys.getenv("AZURE_CLIENT_ID")) {
  # Load config from .env (repo root) if the caller has not already done so.
  # This is the same file db_connect.R uses for Postgres settings.
  env_path <- here::here(".env")
  if (fs::file_exists(env_path)) {
    readRenviron(env_path)
    account_url <- Sys.getenv("STORAGE_ACCOUNT_URL")
    container <- Sys.getenv("CONTAINER")
    tenant <- Sys.getenv("AZURE_TENANT_ID")
    app <- Sys.getenv("AZURE_CLIENT_ID")
  }

  missing <- c(
    STORAGE_ACCOUNT_URL = account_url,
    CONTAINER = container,
    AZURE_TENANT_ID = tenant,
    AZURE_CLIENT_ID = app
  )
  missing <- names(missing)[!nzchar(missing)]
  if (length(missing) > 0L) {
    stop(
      "Missing Azure configuration: ", paste(missing, collapse = ", "),
      ". Set these in data/.env (see WIP/azure-migrate/analyst-setup.md).",
      call. = FALSE
    )
  }

  # Entra ID OAuth token for the blob data plane. Device-code flow works across
  # RStudio / Positron / VS Code with no browser-redirect configuration.
  token <- AzureAuth::get_azure_token(
    resource = "https://storage.azure.com/",
    tenant = tenant,
    app = app,
    auth_type = "device_code"
  )

  AzureStor::blob_endpoint(account_url, token = token) |>
    AzureStor::blob_container(name = container)
}

#' List a chapter's source files in the blob container
#'
#' Returns a tibble of the blobs stored under `data/raw/{chapter}/`, excluding
#' directory placeholder entries. Useful for checking what will be synced before
#' downloading, or for confirming an upload landed.
#'
#' @param chapter Chapter slug, e.g. `"05-environment"`. Must match the blob
#'   folder name exactly.
#' @param cont A blob container from [weca_blob_container()]. Defaults to a fresh
#'   authenticated container.
#'
#' @return A tibble with (at least) `name`, `size`, and `isdir` columns, one row
#'   per file. Zero rows if the prefix contains no files.
#'
#' @examples
#' \dontrun{
#' list_raw_chapter_files("05-environment")
#' }
list_raw_chapter_files <- function(chapter, cont = weca_blob_container()) {
  chapter <- validate_chapter(chapter)
  AzureStor::list_storage_files(
    cont,
    dir = glue::glue("data/raw/{chapter}"),
    info = "all"
  ) |>
    dplyr::as_tibble() |>
    dplyr::filter(!isdir)
}

#' Sync a chapter's raw data from the blob into data/raw/{chapter}/
#'
#' Downloads every file stored under `data/raw/{chapter}/` in the container into
#' the matching local path, overwriting local copies. Run this **before**
#' editing or rendering a chapter you did not author, so you are working from the
#' current central data. Rendering itself never calls this - the download is a
#' deliberate, manual step, which keeps rendering offline-capable and keeps CI
#' (no VPN, no Azure access) rendering from the committed `_freeze/` cache.
#'
#' @param chapter Chapter slug, e.g. `"05-environment"`. Must match the blob
#'   folder name exactly.
#' @param cont A blob container from [weca_blob_container()]. Defaults to a fresh
#'   authenticated container. Pass an existing one to sync several chapters
#'   without re-authenticating.
#'
#' @return Invisibly, the absolute path of the local chapter directory the files
#'   were written to.
#'
#' @section Errors:
#'   \itemize{
#'     \item `chapter` is not a single non-empty string.
#'     \item No files are found under the prefix (wrong slug, nothing uploaded
#'       yet, or VPN off).
#'     \item A download fails (reported per file, with the blob name).
#'   }
#'
#' @examples
#' \dontrun{
#' refresh_raw_chapter_data("05-environment")
#'
#' # Sync several chapters on one sign-in:
#' cont <- weca_blob_container()
#' purrr::walk(c("02-transport", "05-environment"), \(ch) {
#'   refresh_raw_chapter_data(ch, cont = cont)
#' })
#' }
refresh_raw_chapter_data <- function(chapter, cont = weca_blob_container()) {
  chapter <- validate_chapter(chapter)

  files <- list_raw_chapter_files(chapter, cont = cont)
  if (nrow(files) == 0L) {
    stop(
      glue::glue(
        "No files found under 'data/raw/{chapter}/'. Check the chapter slug ",
        "matches the blob folder, that data has been uploaded, and that the ",
        "VPN is on."
      ),
      call. = FALSE
    )
  }

  local_dir <- here::here("data", "raw", chapter)
  message(glue::glue("Syncing {nrow(files)} file(s) into {local_dir} ..."))

  # Blob name mirrors the local path, so dest == here::here(name).
  purrr::walk(files$name, \(blob_name) {
    dest <- here::here(blob_name)
    fs::dir_create(fs::path_dir(dest))
    message("  downloading: ", blob_name)
    tryCatch(
      AzureStor::storage_download(cont, blob_name, dest, overwrite = TRUE),
      error = function(e) {
        stop(
          glue::glue("Failed to download '{blob_name}': {conditionMessage(e)}"),
          call. = FALSE
        )
      }
    )
  })

  message(glue::glue("Done. {nrow(files)} file(s) synced to data/raw/{chapter}/"))
  invisible(local_dir)
}

#' Upload a chapter's raw data to the blob (requires Contributor role)
#'
#' Uploads local files from `data/raw/{chapter}/` to the matching blob path,
#' overwriting the central copies. Requires the **Storage Blob Data Contributor**
#' role; with only Data Reader this errors with a `403`, and you should upload
#' via the Azure Portal instead.
#'
#' @param chapter Chapter slug, e.g. `"05-environment"`.
#' @param files Character vector of local file paths to upload, relative to the
#'   project root. Defaults to every file currently in `data/raw/{chapter}/`.
#' @param cont A blob container from [weca_blob_container()].
#'
#' @return Invisibly, the character vector of blob names uploaded.
#'
#' @examples
#' \dontrun{
#' # Upload one refreshed source file
#' upload_raw_chapter_data(
#'   "05-environment",
#'   files = "data/raw/05-environment/RI_5B1_nondom_epc_a.csv"
#' )
#' }
upload_raw_chapter_data <- function(chapter,
                                    files = NULL,
                                    cont = weca_blob_container()) {
  chapter <- validate_chapter(chapter)
  local_dir <- here::here("data", "raw", chapter)

  if (is.null(files)) {
    files <- fs::dir_ls(local_dir, type = "file", recurse = TRUE) |>
      fs::path_rel(start = here::here())
  }
  if (length(files) == 0L) {
    stop(
      glue::glue("No files to upload under data/raw/{chapter}/."),
      call. = FALSE
    )
  }

  # Normalise to project-relative paths that double as blob names.
  blob_names <- fs::path_rel(fs::path_abs(files, start = here::here()),
                             start = here::here()) |>
    as.character()

  message(glue::glue("Uploading {length(blob_names)} file(s) to data/raw/{chapter}/ ..."))
  purrr::walk(blob_names, \(blob_name) {
    src <- here::here(blob_name)
    if (!fs::file_exists(src)) {
      stop(glue::glue("Local file not found: {blob_name}"), call. = FALSE)
    }
    message("  uploading: ", blob_name)
    tryCatch(
      AzureStor::storage_upload(cont, src, blob_name),
      error = function(e) {
        stop(
          glue::glue("Failed to upload '{blob_name}': {conditionMessage(e)}"),
          call. = FALSE
        )
      }
    )
  })

  message("Done.")
  invisible(blob_names)
}

# --- internal ----------------------------------------------------------------

#' Validate a chapter slug
#'
#' @param chapter Value to validate.
#' @return The trimmed chapter string, or stops with an informative error.
#' @keywords internal
#' @noRd
validate_chapter <- function(chapter) {
  if (!is.character(chapter) || length(chapter) != 1L) {
    stop("`chapter` must be a single character string, e.g. \"05-environment\".",
         call. = FALSE)
  }
  chapter <- trimws(chapter)
  if (is.na(chapter) || !nzchar(chapter)) {
    stop("`chapter` must not be empty or NA.", call. = FALSE)
  }
  chapter
}
