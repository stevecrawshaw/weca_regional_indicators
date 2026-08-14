pacman::p_load(tidyverse, glue, janitor, here)
source(here::here("scripts", "R", "_common.R"))
# RI_5F4_water_catchment_health

RI_5F4_water_catchment_health_path <- here::here(
  "data",
  "raw",
  "RI_5F4_water_catchment_health_ecological_health_water_bristol_avon_somerset_streams.csv"
)

RI_5F4_raw_tbl <- read_csv(RI_5F4_water_catchment_health_path) |>
  clean_names()

RI_5F4_fact_tbl <- RI_5F4_raw_tbl |>
  transmute(
    period_start = as.Date(glue("{year}-01-01")),
    period_end = as.Date(glue("{year}-12-31")),
    value = (good * 100) / grand_total
  )

RI_5F4_start_year <- min(year(RI_5F4_fact_tbl$period_start))
RI_5F4_end_year <- max(year(RI_5F4_fact_tbl$period_start))
RI_5F4_plot <- RI_5F4_fact_tbl |>
  transmute(year = year(period_start), value) |>
  ggplot(aes(x = year, y = value)) +
  scale_y_continuous(
    labels = scales::label_percent(scale = 1),
    limits = c(0, 100)
  ) +
  scale_x_continuous(breaks = seq(RI_5F4_start_year, RI_5F4_end_year, by = 1)) +
  geom_line(color = get_weca_color("west_green")) +
  geom_point(color = get_weca_color("west_green")) +
  labs(
    title = "Proportion of Surface Waters in 'Good' Ecological Health",
    subtitle = "Avon Bristol and Somerset North Streams",
    x = "Year",
    y = NULL,
    caption = "Source: Environment Agency"
  ) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))


RI_5F4_fact_tbl |>
  build_fact("RI_5F4_water_catchment_health") |>
  save_fact()
