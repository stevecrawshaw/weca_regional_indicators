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
      priority_description
    )
}

#' Return DIM rows for all priorities with the priority column as a single digit
#'
#' @param dim_data_tbl The core DIM tibble (e.g. `core_dim_data_tbl`).
#' @return A tibble with columns: indicator_id, indicator_summary, units, priority, polarity.
get_dim_all <- function(dim_data_tbl) {
  dim_data_tbl |>
    mutate(priority = str_extract(priority, "\\d")) |>
    select(
      indicator_id,
      indicator_summary,
      units,
      priority,
      polarity,
      priority_description
    )
}
