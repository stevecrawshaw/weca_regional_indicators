library("tidyverse")
library("here")
library("janitor")
library("readxl")
library("glue")

source(here::here("scripts", "R", "_common.R"))

RI_2_mode_share <- read_excel(
  path = here("data", "raw", "TransportIndicators_Mode.xlsx"),
  sheet = "NTS percent chart"
) |>

  clean_names() |>

  mutate(
    period_start = as.Date(glue("{str_sub(year,1,4)}-01-01")),
    period_end = as.Date(glue("{str_sub(year,9,12)}-12-31"))
  ) |>

  select(period_start, period_end, walking, cycling, car, bus, rail, other) |>

  filter(!is.na(car))

max_year <- year(max(RI_2_mode_share$period_start))

start_year <- max_year - 9

RI_2_mode_share_plot_tbl <- RI_2_mode_share |>
  select(period_start, period_end, walking, cycling, car, bus, rail, other) |>
  filter(year(period_start) >= start_year) |>
  pivot_longer(
    cols = c(walking, cycling, car, bus, rail, other),
    names_to = "mode_type",
    values_to = "value"
  )

mode_colours <- weca_colors[1:6]

mode_colours_named <-
  mode_colours |>
  set_names("walking", "cycling", "car", "bus", "rail", "other")

RI_2_plot <-
  RI_2_mode_share_plot_tbl |>
  ggplot(aes(x = period_start, y = value, fill = mode_type)) +
  geom_col(position = "stack") +
  labs(
    title = "Mode Share in the West of England",
    subtitle = "Department for Transport: National Travel Survey",
    x = "Two year period start",
    y = "%",
    fill = "Mode"
  ) +

  scale_fill_manual(values = mode_colours_named) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

# RI_2_plot

# This is the bit that writes the fact table which is used to make the nice tables in the quarto report
RI_2_mode_share_plot_tbl |>
  filter(mode_type == "car") |>
  mutate(value = 100 * (1 - value)) |>
  select(period_start, period_end, value) |>
  build_fact("RI_2_mode_share") |>
  save_fact()
