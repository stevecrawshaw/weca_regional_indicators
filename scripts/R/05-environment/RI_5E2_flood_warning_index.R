pacman::p_load(tidyverse, glue, janitor, here)
source(here::here("scripts", "R", "_common.R"))

# RI_5E2_flood_warning_index
# data is hosted on github and provided through the FWII project, which is a composite index of flood warning indicators. The data is updated annually and the latest version is available at the following URL: https://github.com/stevecrawshaw/fwii
#
RI_5E2_raw_tbl <- read_csv(
  "https://raw.githubusercontent.com/stevecrawshaw/fwii/refs/heads/main/data/outputs/fwii_timeseries.csv"
)


RI_5E2_flood_warning_index_fact_tbl <- RI_5E2_raw_tbl |>
  transmute(
    period_start = as.Date(glue("{year}-01-01")),
    period_end = as.Date(glue("{year}-12-31")),
    value = composite_fwii
  )

RI_5E2_flood_warning_index_plot <- RI_5E2_flood_warning_index_fact_tbl |>
  ggplot(aes(x = period_start, y = value)) +
  geom_line(color = "#40A832", linewidth = 1) +
  geom_point(size = 2, color = "#40A832") +
  geom_hline(
    yintercept = 100,
    linetype = "dashed",
    color = get_weca_color("forest_green")
  ) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(limits = c(0, 200)) +
  labs(
    title = "Flood Warning Intensity Index",
    subtitle = "Composite index of flood warning indicators",
    x = "Year",
    y = "FWII",
    caption = "Index relative to 2020 baseline"
  ) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

# RI_5E2_flood_warning_index_plot

RI_5E2_flood_warning_index_fact_tbl |>
  build_fact("RI_5E2_flood_warning_index") |>
  save_fact()
