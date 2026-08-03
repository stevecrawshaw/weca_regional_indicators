library(tidyverse)
library(here)
library(janitor)
library(readxl)
library(glue)


file.exists(here("data", "common_project_data", "indicators-master.xlsx")) |>
  stopifnot()
# reconcile with validation list in Reference tab
# of indicators_master.xlsx
valid_unit_types <- c(
  "percent",
  "count",
  "currency",
  "rate",
  "index",
  "score",
  "ratio"
)


core_dim_data_tbl <- read_excel(
  here("data", "common_project_data", "indicators-master.xlsx"),
  sheet = "indicators",
  range = "A2:AP100"
) |>
  filter(!is.na(indicator_id), include)

stopifnot(all(core_dim_data_tbl$unit_type %in% valid_unit_types))

get_dim_priority <- function(dim_data_tbl, priority) {
  p_str <- as.character(priority)
  dim_data_tbl |>
    filter(priority |> str_extract("\\d") == p_str) |>
    select(
      indicator_id,
      indicator_summary,
      units,
      polarity,
      priority_description,
      order_within_priority,
      unit_type
    )
}

#' Return DIM rows for all priorities with the priority column as a single digit
#'
#' @param dim_data_tbl The core DIM tibble (e.g. `core_dim_data_tbl`).
#' @return A tibble with columns: indicator_id, indicator_summary, units, priority, polarity, order_within_priority.
get_dim_all <- function(dim_data_tbl) {
  dim_data_tbl |>
    mutate(priority = str_extract(priority, "\\d")) |>
    select(
      indicator_id,
      indicator_summary,
      units,
      priority,
      polarity,
      priority_description,
      order_within_priority,
      unit_type
    )
}

#' Return the DIM row for a single indicator
#'
#' @param dim_data_tbl The core DIM tibble (e.g. `core_dim_data_tbl`).
#' @param indicator_id Character scalar identifying the row to return.
#' @return A one-row tibble with `units`, `unit_type`, `polarity`, etc.
get_dim_indicator <- function(dim_data_tbl, indicator_id) {
  row <- dim_data_tbl |> filter(indicator_id == .env$indicator_id)
  if (nrow(row) == 0L) {
    stop("No DIM row for indicator_id '", indicator_id,
      "'. Check indicators-master.xlsx (and its `include` flag).",
      call. = FALSE)
  }
  if (nrow(row) > 1L) {
    stop("Multiple DIM rows for indicator_id '", indicator_id,
      "'. indicators-master.xlsx should have one row per indicator.",
      call. = FALSE)
  }
  row
}

#' Stop if any row is missing `order_within_priority`
#'
#' Called after joining DIM data to FACT-backed indicators, so it only fires
#' for indicators actually appearing in a summary table (not the whole master
#' sheet, some rows of which may legitimately lack FACT data yet).
#'
#' @param tbl A tibble with `indicator_id` and `order_within_priority` columns.
#' @keywords internal
check_order_within_priority <- function(tbl) {
  missing_order <- tbl |>
    filter(is.na(order_within_priority)) |>
    pull(indicator_id)

  if (length(missing_order) > 0L) {
    stop(
      "`order_within_priority` is missing for indicator(s): ",
      paste(missing_order, collapse = ", "),
      ". Set this in indicators-master.xlsx before rendering.",
      call. = FALSE
    )
  }
  invisible(tbl)
}
