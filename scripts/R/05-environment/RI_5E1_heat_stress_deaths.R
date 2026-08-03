pacman::p_load(tidyverse, glue, janitor, here, readODS)
source(here::here("scripts", "R", "_common.R"))

# RI_5E1_heat_stress_deaths

RI_5E1_path_2024 <- here::here(
  "data",
  "raw",
  "heat-mortality-monitoring-data-2024.ods"
)

RI_5E1_path_2025 <- here::here(
  "data",
  "raw",
  "heat-mortality-monitoring-report-England-2025-data.ods"
)

get_deaths <- function(path, sheet = "Table_3", skip = 3) {
  deaths <- read_ods(path, sheet = sheet, skip = skip) |>
    clean_names() |>
    filter(str_starts(local_resilience_forum_area, "Avon")) |>
    pull(heat_associated_deaths_per_million_population)

  the_year <- str_extract(path, "[0-9]{4}") |>
    as.integer()
  period_start <- as.Date(glue("{the_year}-01-01"))
  period_end <- as.Date(glue("{the_year}-12-31"))
  fact_vec <- list(
    "period_start" = period_start,
    "period_end" = period_end,
    "value" = deaths
  )
  fact_vec
}

deaths_list <- list(
  get_deaths(RI_5E1_path_2024),
  get_deaths(RI_5E1_path_2025)
)

RI_5E1_heat_stress_deaths_fact_tbl <-
  deaths_list |>
  bind_rows()

RI_5E1_start_year <- min(year(RI_5E1_heat_stress_deaths_fact_tbl$period_start))
RI_5E1_end_year <- max(year(RI_5E1_heat_stress_deaths_fact_tbl$period_start))

RI_5E1_heat_stress_deaths_plot <- RI_5E1_heat_stress_deaths_fact_tbl |>
  transmute(year = year(period_start), value) |>
  ggplot(aes(x = year, y = value)) +
  scale_y_continuous(labels = scales::comma, limits = c(0, 50)) +
  scale_x_continuous(breaks = seq(RI_5E1_start_year, RI_5E1_end_year, by = 1)) +
  geom_line(color = "#40A832", linewidth = 1) +
  geom_point(size = 2, color = "#40A832") +
  labs(
    title = "Heat mortality associated deaths per million population",
    subtitle = "Avon Local Resilience Forum Area",
    x = "Year",
    y = "Deaths\nper million\npopulation",
    caption = "Source: UK Health Security Agency"
  ) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

RI_5E1_heat_stress_deaths_fact_tbl |>
  build_fact(indicator_id = "RI_5E1_heat_stress_deaths") |>
  save_fact()
