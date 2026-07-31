pacman::p_load(tidyverse, glue, janitor, here)
source(here::here("scripts", "R", "_common.R"))

# RI_5F1_tree_canopy

RI_5F1_index_year <- 2020
RI_5F1_nfi_url <- "https://raw.githubusercontent.com/stevecrawshaw/forest-cover-lep/refs/heads/main/data/output/forest_cover_lep.csv"

RI_5F1_tow_url <- "https://raw.githubusercontent.com/stevecrawshaw/forest-cover-lep/refs/heads/main/data/output/tow_cover_lep.csv"

RI_5F1_nfi_tbl <- read_csv(RI_5F1_nfi_url) |>
  filter(Year >= RI_5F1_index_year) |>
  mutate(
    period_start = as.Date(glue("{Year}-01-01")),
    period_end = as.Date(glue("{Year}-12-31")),
    value = Hectares
  )

RI_5F1_index_value <- RI_5F1_nfi_tbl |>
  filter(Year == RI_5F1_index_year) |>
  pull(Hectares)

RI_5F1_index_tbl <- RI_5F1_nfi_tbl |>
  mutate(index = (Hectares - RI_5F1_index_value) * 100 / Hectares)

RI_5F1_plot <- RI_5F1_index_tbl |>
  ggplot(aes(x = Year, y = index)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_y_continuous(
    labels = scales::label_percent(scale = 1),
    limits = c(-1, 1)
  ) +
  labs(
    title = "Change in extent of National Forest Inventory Woodland",
    subtitle = "From 2020 baseline: West of England",
    x = "Year",
    y = "%",
    caption = "Source: Forestry Commission"
  ) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

RI_5F1_fact_tbl <- RI_5F1_nfi_tbl |>
  select(period_start, period_end, value)

RI_5F1_fact_tbl |>
  build_fact(indicator_id = "RI_5F1_tree_canopy") |>
  save_fact()
