# libraries ---------------------
#pacman::p_load(tidyverse, janitor, glue, here, lubridate, readxl)

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
# RI_3A3 – Non-decent homes (proportion)
# ------------------------------------------------------------

path_3A3 <- here::here("data", "raw", "3A3.xlsx")

RI_3A3_raw_tbl <- read_excel(path_3A3, skip = 1) |>
  clean_names()

RI_3A3_long_tbl <- RI_3A3_raw_tbl |>
  pivot_longer(
    cols = -year,
    names_to = "area",
    values_to = "value"
  ) |>
  mutate(
    area = recode(
      area,
      "banes" = "Bath and North East Somerset",
      "bristol" = "Bristol",
      "north_somerset" = "North Somerset",
      "south_gloucestershire" = "South Gloucestershire"
    ),
    period_end = ymd(str_c(str_sub(year, 6, 7), "-03-31")),
    period_start = period_end - years(1) + days(1)
  ) |>
  filter(!is.na(period_start), !is.na(period_end)) |>
  select(area, period_start, period_end, value)

RI_3A3_weca_tbl <- RI_3A3_long_tbl |>
  group_by(period_start, period_end) |>
  summarise(
    value = mean(value, na.rm = TRUE),
    area = "West of England",
    .groups = "drop"
  )

RI_3A3_plot_tbl <- bind_rows(RI_3A3_long_tbl, RI_3A3_weca_tbl)

RI_3A3_plot <- RI_3A3_plot_tbl |>
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
    breaks = sort(unique(year(RI_3A3_plot_tbl$period_end)))
  ) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    title = "Non-decent Homes",
    subtitle = "Proportion of dwellings failing the Decent Homes Standard",
    x = "Year",
    y = "%",
    colour = NULL,
    caption = "Source: EHS LA Stock Condition Modelling (2024), WECA synthetic time series"
  ) +
  theme_ua() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5),
    legend.position = "bottom"
  ) +
  guides(colour = guide_legend(ncol = 2))

RI_3A3_fact_tbl <- RI_3A3_weca_tbl |>
  mutate(value = value * 100) |>
  select(period_start, period_end, value)

RI_3A3_fact_tbl |>
  build_fact(indicator_id = "RI_3A3_non_decent_homes") |>
  save_fact()
