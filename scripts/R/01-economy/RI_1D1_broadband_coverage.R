library(tidyverse)
library(here)
source(here::here("scripts", "R", "_common.R"))

# RI_1D1_broadband_coverage

RI_1D1_raw_tbl <- read_csv(
  here::here(
    "data",
    "raw",
    "broadband_coverage_weighted.csv"
  ),
  col_types = cols(
    date = col_date(format = "%d/%m/%Y"),
    superfast_coverage = col_double(),
    gigabit_coverage = col_double()
  )
)


RI_1D1_plot <- ggplot(RI_1D1_raw_tbl, aes(x = date)) +
  geom_line(
    aes(y = superfast_coverage, color = "Superfast (30mbps)"),
    linewidth = 1,
    na.rm = TRUE
  ) +
  geom_line(
    aes(y = gigabit_coverage, color = "Gigabit (1000mbps)"),
    linewidth = 1,
    na.rm = TRUE
  ) +
  geom_point(
    aes(y = superfast_coverage, color = "Superfast (30mbps)"),
    size = 2,
    na.rm = TRUE
  ) +
  geom_point(
    aes(y = gigabit_coverage, color = "Gigabit (1000mbps)"),
    size = 2,
    na.rm = TRUE
  ) +
  scale_color_manual(
    values = c(
      "Superfast (30mbps)" = "#40A832",
      "Gigabit (1000mbps)" = "#590075"
    )
  ) +
  labs(
    title = "Broadband coverage",
    subtitle = "West of England (weighted)",
    y = "Coverage\n(%)",
    x = "Year",
    caption = "Source: Ofcom Connected Nations"
  ) +
  theme_weca() +
  theme(
    legend.title = element_blank(),
    legend.text = element_text(size = 11),
    axis.title.y = element_text(angle = 0, vjust = 0.5),
  ) +
  scale_x_date(
    date_breaks = "1 year",
    date_labels = "%Y"
  )

# RI_1D1_plot

# fact table

RI_1D1_fact_tbl <- RI_1D1_raw_tbl |>
  arrange(date) |>
  transmute(
    period_start = date,
    period_end = lead(
      date,
      default = (make_date(year(max(date)), 12, 31) + 1)
    ) -
      days(1),
    value = superfast_coverage
  )

RI_1D1_fact_tbl |>
  build_fact("RI_1D1_broadband_coverage") |>
  save_fact()
