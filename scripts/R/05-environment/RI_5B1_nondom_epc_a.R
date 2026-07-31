pacman::p_load(tidyverse, glue, janitor, here)
source(here::here("scripts", "R", "_common.R"))


RI_5B1_nondom_epc_a_url <-
  "https://opendata.westofengland-ca.gov.uk/api/explore/v2.1/catalog/datasets/epc_non_domestic_lep_ods/exports/csv/?lang=en&select=asset_rating_band%2C+lodgement_date%2C+certificate_number&timezone=Europe%2FLondon"

# RI_5B1_nondom_epc_a
RI_5B1_nondom_epc_a_path <- here::here(
  "data",
  "raw",
  "RI_5B1_nondom_epc_a.csv"
)

f_exists <- fs::file_exists(RI_5B1_nondom_epc_a_path)
f_modified_dttm <- fs::file_info(RI_5B1_nondom_epc_a_path)$modification_time
old_file <- difftime(Sys.time(), f_modified_dttm, units = "weeks") > 1

if ((f_exists && old_file) || !f_exists) {
  RI_5B1_nondom_epc_a_raw_tbl <- read_csv2(
    RI_5B1_nondom_epc_a_url
  )
  RI_5B1_nondom_epc_a_raw_tbl |> write_csv2(RI_5B1_nondom_epc_a_path)
  print(glue("Downloading csv file from {RI_5B1_nondom_epc_a_url}"))
} else if (f_exists && !old_file) {
  RI_5B1_nondom_epc_a_raw_tbl <- read_csv2(
    RI_5B1_nondom_epc_a_path
  )
  print(glue("using stored csv file from {f_modified_dttm}"))
}


max_date <- max(RI_5B1_nondom_epc_a_raw_tbl$lodgement_date)
start_date <- max_date - (years(9))


#' @param raw_tbl: a tibble with at least the columns specified in the function arguments: EPC data
#' @param cat_vec: vector of EPC categories to include in the "in_cat" group
#' @param date_col: the date column to use for ordering and grouping the data
#' @return a tibble with monthly proportions of properties in the specified EPC categories, along with period start and end dates
make_cumulative_prop_tbl <- function(
  raw_tbl,
  cat_vec = c("A", "A+"),
  date_col = lodgement_date
) {
  raw_tbl |>
    arrange({{ date_col }}) |>
    mutate(in_cat = if_else(asset_rating_band %in% cat_vec, TRUE, FALSE)) |>
    group_by(ym = format({{ date_col }}, "%Y-%m")) |>
    summarise(count_in_cat = sum(in_cat), cert_count = n(), .groups = "drop") |>
    mutate(
      period_start = as.Date(glue("{ym}-01")),
      period_end = ym(ym) |> rollforward(),
      value = cumsum(count_in_cat) * 100 / cumsum(cert_count),
      ym = NULL,
      count_in_cat = NULL,
      cert_count = NULL
    )
}

RI_5B1_nondom_epc_a_fact_tbl <- make_cumulative_prop_tbl(
  RI_5B1_nondom_epc_a_raw_tbl,
  cat_vec = c("A", "A+")
) |>
  filter(period_start >= start_date)

RI_5B1_nondom_epc_a_plot <- RI_5B1_nondom_epc_a_fact_tbl |>
  ggplot(aes(x = period_end, y = value)) +
  geom_line() +
  geom_point(size = 2) +
  labs(
    title = "Proportion of non-domestic properties with EPC rating A or A+",
    subtitle = "Cumulative monthly proportions",
    x = "Date",
    y = "%",
    caption = "Source: MHCLG"
  ) +
  scale_y_continuous(
    labels = scales::label_percent(scale = 1),
    limits = c(0, 100)
  ) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

RI_5B1_nondom_epc_a_plot

RI_5B1_nondom_epc_a_fact_tbl |>
  build_fact(indicator_id = "RI_5B1_nondom_epc_a") |>
  save_fact()
