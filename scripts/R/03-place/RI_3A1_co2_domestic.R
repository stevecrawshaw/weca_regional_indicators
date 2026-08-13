# libraries ---------------------

library(tidyverse)
library(readxl)
library(janitor)
library(lubridate)
library(here)
library(glue)

source(here::here("scripts", "R", "_common.R"))

# ------------------------------------------------------------
# RI_3A1 – Domestic CO₂ emissions (kt CO₂), LA time series
# ------------------------------------------------------------

path_3A1 <- here::here("data", "raw", "3A1.xlsx")

# your read_excel was bringing in a mostly blank header row
# so you weren't getting the col names you expected
# you can specify a range
RI_3A1_raw_tbl <- read_excel(path_3A1, sheet = 1, range = "A2:U6") |>
  clean_names()


# Expecting columns:
# la, 2005, 2006, ..., 2024

RI_3A1_long_tbl <- RI_3A1_raw_tbl |>
  pivot_longer(
    cols = -la,
    names_to = "year_raw",
    values_to = "value"
  ) |>
  mutate(
    year = as.integer(str_remove(year_raw, "x")),
    area = if_else(la == "Bath & North East Somerset",
                        "Bath and North East Somerset",
                         la),
    period_end = make_date(year, 12, 31),
    period_start = make_date(year, 1, 1)
  ) |>
  filter(!is.na(period_start), !is.na(period_end)) |>
  select(area, period_start, period_end, value)

max_date <- max(RI_3A1_long_tbl$period_start)
start_date <- max_date - years(9)

# ------------------------------------------------------------
# WECA aggregation
# ------------------------------------------------------------

RI_3A1_weca_tbl <- RI_3A1_long_tbl |>
  group_by(period_start, period_end) |>
  summarise(
    value = sum(value, na.rm = TRUE),
    area = "West of England",
    .groups = "drop"
  ) |>
  filter(period_start >= start_date)

RI_3A1_plot_tbl <- bind_rows(RI_3A1_long_tbl, RI_3A1_weca_tbl) |>
  filter(period_start >= start_date)

# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------

RI_3A1_plot <- RI_3A1_plot_tbl |>
  mutate(year = year(period_end)) |>
  ggplot(aes(x = year, y = value, colour = area, group = area)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_colour_manual(
    values = c(
      ua_colors_by_name,
      "West of England" = "#40A832"
    )
  ) +
  scale_x_continuous(
    breaks = sort(unique(year(RI_3A1_plot_tbl$period_end)))
  ) +
  labs(
    title = "Domestic CO₂ Emissions",
    subtitle = "kt CO₂, annual",
    x = "Year",
    y = "kt CO₂",
    colour = NULL,
    caption = "Source: DESNZ Local Authority CO₂ Emissions (2005–2024)"
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

RI_3A1_fact_tbl <- RI_3A1_weca_tbl |>
  select(period_start, period_end, value)

RI_3A1_fact_tbl |>
  build_fact(indicator_id = "RI_3A1_co2_domestic") |>
  save_fact()

# ------------------------------------------------------------
# Optional indicator summary (only if function exists)
# ------------------------------------------------------------
