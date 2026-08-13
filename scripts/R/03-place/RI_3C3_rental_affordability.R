# libraries ---------------------

library(tidyverse)
library(readxl)
library(janitor)
library(lubridate)
library(here)
library(glue)

source(here::here("scripts", "R", "_common.R"))

# ------------------------------------------------------------
# RI_3C3 – Rental affordability
# ------------------------------------------------------------

path_3C3 <- here::here("data", "raw", "3C3.xlsx")

# same issue as RI_3A1 – specify the rectangular range
RI_3C3_raw_tbl <- read_excel(path_3C3, sheet = 1, range = "A2:L6") |>
  clean_names()

# Expecting columns:
# la, 2016, 2017, ..., 2026

RI_3C3_long_tbl <- RI_3C3_raw_tbl |>
  pivot_longer(
    cols = -la,
    names_to = "year_raw",
    values_to = "value"
  ) |>
  mutate(
    # Extract the 4-digit year
    year = str_extract(year_raw, "\\d{4}") |> as.integer(),

    # area column required downstream
    area = if_else(la == "Bath & North East Somerset",
                   "Bath and North East Somerset",
                   la),

    # Rental affordability → annual period ending mid-year
    period_end = make_date(year, 6, 30),
    period_start = period_end - years(1) + days(1)
  ) |>
  filter(!is.na(period_start), !is.na(period_end)) |>
  select(area, period_start, period_end, value)

# ------------------------------------------------------------
# WECA aggregation
# ------------------------------------------------------------

RI_3C3_weca_tbl <- RI_3C3_long_tbl |>
  group_by(period_start, period_end) |>
  summarise(
    value = median(value, na.rm = TRUE),
    area = "West of England",
    .groups = "drop"
  )

RI_3C3_plot_tbl <- bind_rows(RI_3C3_long_tbl, RI_3C3_weca_tbl)

# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------

RI_3C3_plot <- RI_3C3_plot_tbl |>
  mutate(year = year(period_end)) |>
  ggplot(aes(x = year, y = value, colour = area, group = area)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_colour_manual(
    values = c(
      ua_colors_by_name,
      "West of England" = "#40A832"
    )
  ) +
  scale_x_continuous(
    breaks = sort(unique(year(RI_3C3_plot_tbl$period_end)))
  ) +
  labs(
    title = "Rental Affordability",
    subtitle = "Median monthly private rent (£)",
    x = "Year",
    y = "£ per month",
    colour = NULL,
    caption = "Source: Local Authority rent time series (PRMS anchors)"
  ) +
  theme_ua() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5),
    legend.position = "bottom"
  ) +
  guides(colour = guide_legend(ncol = 2))

# ------------------------------------------------------------
# Fact table
# ------------------------------------------------------------

RI_3C3_fact_tbl <- RI_3C3_weca_tbl |>
  select(period_start, period_end, value) |>
  filter(!is.na(value))

RI_3C3_fact_tbl |>
  build_fact(indicator_id = "RI_3C3_rental_affordability") |>
  save_fact()
