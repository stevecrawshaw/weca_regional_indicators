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
# RI_3C4 – Temporary accommodation (Q4 total households)
# ------------------------------------------------------------

path_3C4 <- here::here("data", "raw", "3C4.xlsx")

# Use a defined range to avoid header/footer issues
RI_3C4_raw_tbl <- read_excel(path_3C4, sheet = 1, range = "A2:H7") |>
  clean_names()


RI_3C4_long_tbl <- RI_3C4_raw_tbl |>
  pivot_longer(
    cols = -la,
    names_to = "year_raw",
    values_to = "value"
  ) |>
  mutate(
    # Extract the 4-digit year from the column name
    year = as.integer(str_remove(year_raw, "x")),

    area = recode(
      la,
      "B&NES" = "Bath and North East Somerset",
      "Bristol" = "Bristol",
      "North_Somerset" = "North Somerset",
      "South_Gloucestershire" = "South Gloucestershire"
    ),

    # Q4 indicator → period_end = 31 December
    period_end = make_date(year, 12, 31),
    period_start = period_end - years(1) + days(1)
  ) |>
  filter(!is.na(period_start), !is.na(period_end)) |>
  select(area, period_start, period_end, value)

# ------------------------------------------------------------
# WECA aggregation
# ------------------------------------------------------------

RI_3C4_weca_tbl <- RI_3C4_long_tbl |>
  group_by(period_start, period_end) |>
  summarise(
    value = median(value, na.rm = TRUE),
    area = "West of England",
    .groups = "drop"
  )

RI_3C4_plot_tbl <- bind_rows(RI_3C4_long_tbl, RI_3C4_weca_tbl)

# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------

RI_3C4_plot <- RI_3C4_plot_tbl |>
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
    breaks = sort(unique(year(RI_3C4_plot_tbl$period_end)))
  ) +
  labs(
    title = "Households in Temporary Accommodation (Q4 snapshot)",
    subtitle = "Total households in TA (TA1)",
    x = "Year",
    y = "Households",
    colour = NULL,
    caption = "Source: WECA compiled Q4 temporary accommodation dataset"
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

RI_3C4_fact_tbl <- RI_3C4_weca_tbl |>
  select(period_start, period_end, value)

RI_3C4_fact_tbl |>
  build_fact(indicator_id = "RI_3C4_temp_accommodation") |>
  save_fact()
