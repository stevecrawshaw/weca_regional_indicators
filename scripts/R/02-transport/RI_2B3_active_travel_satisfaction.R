library("tidyverse")
library("here")
library("janitor")
library("readxl")
library("glue")

source(here::here("scripts", "R", "_common.R"))

RI_2B3_active_travel_satisfaction <- read_excel(
  path = here("data", "raw", "Authority Result download 2025 - WoECA.xlsx"),
  sheet = "Indicator",
  skip = 2
) |>

  clean_names() |>

  mutate(
    period_start = as.Date(glue("{year}-01-01")),
    period_end = as.Date(glue("{year}-12-31"))
  ) |>

  select(
    period_start,
    period_end,
    wof_e_walking,
    wof_e_cycling,
    wof_e_walking_cycling
  )

max_year <- year(max(RI_2B3_active_travel_satisfaction$period_start))

start_year <- max_year - 9

RI_2B3_active_travel_satisfaction_plot_tbl <- RI_2B3_active_travel_satisfaction |>
  select(
    period_start,
    period_end,
    wof_e_walking,
    wof_e_cycling,
    wof_e_walking_cycling
  ) |>
  filter(year(period_start) >= start_year) |>

  pivot_longer(
    cols = c(wof_e_walking, wof_e_cycling, wof_e_walking_cycling),
    names_to = "mode_type",
    values_to = "value"
  ) |>
  mutate(
    mode_type = case_when(
      mode_type == "wof_e_walking" ~ "Walk",
      mode_type == "wof_e_cycling" ~ "Cycle",
      mode_type == "wof_e_walking_cycling" ~ "Active Travel"
    )
  )


at_satisfaction_colours <- weca_colors[1:3]

at_sat_colours_named <-
  at_satisfaction_colours |>
  set_names("Walk", "Cycle", "Active Travel")

RI_2B3_plot <-
  RI_2B3_active_travel_satisfaction_plot_tbl |>
  ggplot(aes(x = period_start, y = value, fill = mode_type)) +
  geom_col(position = "dodge") +
  labs(
    title = "Active Travel Satisfaction",
    subtitle = "% of people surveyed by National Highways and Transport",
    x = "Year",
    y = "%",
    fill = "Mode"
  ) +

  scale_fill_manual(values = at_sat_colours_named) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

# RI_2B3_plot

RI_2B3_active_travel_satisfaction_plot_tbl |>
  filter(mode_type == "Active Travel") |>
  select(period_start, period_end, value) |>
  build_fact("RI_2B3_active_travel_satisfaction") |>
  save_fact()
