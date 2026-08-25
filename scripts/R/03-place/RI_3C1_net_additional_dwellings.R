# libraries ---------------------
pacman::p_load(tidyverse, janitor, glue, here, lubridate, readxl)

# Hybrid approach: explicitly attach namespaces so Positron's language server
# recognises all functions and stops producing "No symbol named ..." diagnostics.
library(tidyverse)
library(readxl)
library(janitor)
library(lubridate)
library(here)
library(glue)

source(here::here("scripts", "R", "_common.R"))

# ------------------------------------------------------------
# RI_3C1 – Net additional dwellings (LA time series)
# ------------------------------------------------------------

path_3C1 <- here::here("data", "raw", "3C1.xlsx")

# same issue as RI_3A1 – by default read_excel() will read from the first line
# which is mostly empty. specify the range
RI_3C1_raw_tbl <- read_excel(path_3C1, sheet = 1, range = "A2:L6") |>
  clean_names()

# Expecting columns:
# la, 2015, 2016, ..., 2025

RI_3C1_long_tbl <- RI_3C1_raw_tbl |>
  pivot_longer(
    cols = -la,
    names_to = "year_raw",
    values_to = "value"
  ) |>
  mutate(
    # Extract the first 4-digit year from messy labels
    year = str_extract(year_raw, "\\d{4}") |> as.integer(),

    # area column required downstream
    area = if_else(la == "Bath & North East Somerset",
                  "Bath and North East Somerset", la),

    # Net additions are annual, ending 31 March
    period_end = make_date(year, 3, 31),
    period_start = period_end - years(1) + days(1)
  ) |>
  filter(!is.na(period_start), !is.na(period_end)) |>
  select(area, period_start, period_end, value)

# ------------------------------------------------------------
# WECA aggregation
# ------------------------------------------------------------

RI_3C1_weca_tbl <- RI_3C1_long_tbl |>
  group_by(period_start, period_end) |>
  summarise(
    value = sum(value, na.rm = TRUE),
    area = "West of England",
    .groups = "drop"
  )

RI_3C1_plot_tbl <- bind_rows(RI_3C1_long_tbl, RI_3C1_weca_tbl)

# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------

RI_3C1_plot <- RI_3C1_plot_tbl |>
  mutate(year = year(period_end)) |>
  ggplot(aes(x = year, y = value, colour = area, group = area)) +
  geom_line() +
  geom_point() +
  scale_colour_manual(
    values = c(
      ua_colors_by_name,
      "West of England" = "#40A832"
    )
  ) +
  scale_x_continuous(
    breaks = sort(unique(year(RI_3C1_plot_tbl$period_end)))
  ) +
  labs(
    title = "Net Additional Dwellings",
    subtitle = "Annual net additions to the housing stock",
    x = "Year",
    y = "Dwellings",
    colour = NULL,
    caption = "Source: DHLUC Housing Supply: Net Additional Dwellings"
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

RI_3C1_fact_tbl <- RI_3C1_weca_tbl |>
  select(period_start, period_end, value)

RI_3C1_fact_tbl |>
  build_fact(indicator_id = "RI_3C1_net_additional_dwellings") |>
  save_fact()
