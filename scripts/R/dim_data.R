pacman::p_load(
  tidyverse,
  here,
  janitor,
  readxl,
  glue
)


file.exists(here("data", "common_project_data", "indicators-master.xlsx")) |>
  stopifnot()

core_dim_data_tbl <- read_excel(
  here("data", "common_project_data", "indicators-master.xlsx"),
  sheet = "indicators",
  range = "A2:AM100"
) |>
  filter(!is.na(indicator_id))


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
      order_within_priority
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
      order_within_priority
    )
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
