library(tidyverse)
library(glue)
library(janitor)
library(here)
library(httr2)

source(here::here("scripts", "R", "_common.R"))

# RI_3A2_homes_epc_c_plus

# Steve Crawshaw
# We'll use the opendatasoft API to get the data

#' @param cat_vec character vector of EPC categories to include in the count. Use "all" to include all categories.
#' @return A tibble with monthly counts of properties in the specified EPC categories and total counts for all categories.
#'
RI_3A2_get_epc_month_tbl <- function(cat_vec = c("A", "B", "C")) {
  stopifnot(
    is.character(cat_vec),
    length(cat_vec) > 0
  )

  if (length(cat_vec) == 1 && cat_vec == "all") {
    count_col <- "count_all"
    where_clause <- ""
  } else {
    count_col <- glue("count_{str_c(cat_vec, collapse = '_')}")
    where_clause <- str_c(
      "current_energy_rating IN (",
      glue_collapse(
        single_quote({
          cat_vec
        }),
        sep = ", "
      ),
      ")"
    )
  }
  RI_3A2_base_url <- "https://opendata.westofengland-ca.gov.uk/api/explore/v2.1/catalog/datasets/epc_domestic_lep_ods/exports/csv"

  request(RI_3A2_base_url) |>
    req_method("GET") |>
    req_url_query(
      select = glue("count(certificate_number) AS {count_col}"),
      where = where_clause,
      order_by = "date_format(lodgement_datetime, 'YYYY-MM')",
      group_by = "date_format(lodgement_datetime, 'YYYY-MM') AS year_month",
      limit = "-1",
      timezone = "UTC",
      use_labels = "false",
      compressed = "false",
      epsg = "4326",
    ) |>
    req_headers(
      accept = "*/*",
    ) |>
    req_perform() |>
    resp_body_string() |>
    I() |>
    read_csv2()
}

RI_3A2_in_cat_tbl <- RI_3A2_get_epc_month_tbl(cat_vec = c("A", "B", "C"))
RI_3A2_all_tbl <- RI_3A2_get_epc_month_tbl(cat_vec = "all")

RI_3A2_last_month <- max(as.Date(glue("{RI_3A2_in_cat_tbl$year_month}-01")))
RI_3A2_start_date <- RI_3A2_last_month - years(10)

RI_3A2_fact_tbl <- RI_3A2_in_cat_tbl |>
  inner_join(RI_3A2_all_tbl, by = "year_month") |>
  mutate(
    period_start = as.Date(glue("{year_month}-01")),
    period_end = parse_date(year_month, format = "%Y-%m") |>
      rollforward(),
    value = cumsum(count_A_B_C) * 100 / cumsum(count_all),
    year_month = NULL,
    count_A_B_C = NULL,
    count_all = NULL
  ) |>
  filter(period_start >= RI_3A2_start_date) |>
  glimpse()

RI_3A2_plot <- RI_3A2_fact_tbl |>
  ggplot(aes(x = period_end, y = value)) +
  geom_line(color = get_weca_color("west_green")) +
  # geom_point(color = get_weca_color("west_green")) +
  labs(
    title = "Proportion of Homes with EPC rating C or better",
    subtitle = "Cumulative monthly proportions",
    x = "Date",
    y = NULL,
    caption = "Source: MHCLG"
  ) +
  scale_y_continuous(
    labels = scales::label_percent(scale = 1),
    limits = c(0, 100)
  ) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

# RI_3A2_plot

RI_3A2_fact_tbl |>
  build_fact(indicator_id = "RI_3A2_homes_epc_c_plus") |>
  save_fact()
