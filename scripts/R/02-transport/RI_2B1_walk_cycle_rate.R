library("tidyverse")
library("here")
library("janitor")
library("readxl")
library("glue")

source(here::here("scripts", "R", "_common.R"))

RI_2B1_walk_cycle_rate <- read_excel(
  path = here("data", "raw", "ActiveLivesDataExport.xlsx"),
  sheet = "TransposedData",
  skip = 3
) |>

  clean_names() |>

  mutate(
    period_start = make_date(year(survey_date), 4, 1),
    period_end = make_date(year(survey_date) + 1, 3, 31),
    cycle = 100 * cycling_for_travel,
    walk = 100 * walking_for_travel,
    cycle_England = 100 * cycling_england,
    walk_England = 100 * walking_england,
    active_WofE = 100 * active_travel_wof_e,
    active_England = 100 * active_travel_england
  ) |>

  select(
    period_start,
    period_end,
    cycle,
    walk,
    cycle_England,
    walk_England,
    active_WofE,
    active_England
  )

max_year <- year(max(RI_2B1_walk_cycle_rate$period_start))

start_year <- max_year - 9

RI_2B1_walk_cycle_rate_plot_tbl <- RI_2B1_walk_cycle_rate |>
  select(
    period_start,
    period_end,
    cycle,
    walk,
    cycle_England,
    walk_England,
    active_WofE,
    active_England
  ) |>

  filter(year(period_start) >= start_year) |>

  pivot_longer(
    cols = c(cycle, walk, active_WofE),
    names_to = "mode_type",
    values_to = "value"
  ) |>
  mutate(
    mode_type = case_when(
      mode_type == "cycle" ~ "Cycle",
      mode_type == "walk" ~ "Walk",
      mode_type == "active_WofE" ~ "Active Travel"
    )
  )


walk_cycle_colours <- weca_colors[1:3]

walk_cycle_colours_named <-
  walk_cycle_colours |>
  set_names("Cycle", "Walk", "Active Travel")

#assign plot table to plot
RI_2B1_plot <-
  RI_2B1_walk_cycle_rate_plot_tbl |>
  ggplot(aes(x = period_end, y = value, fill = mode_type)) +
  geom_col(position = "dodge") +
  labs(
    title = "Active Travel participation",
    subtitle = "% participating at least twice in the past 28 days",
    x = "Year",
    y = "%",
    fill = "Mode"
  ) +

  scale_fill_manual(values = walk_cycle_colours_named) +
  theme_weca() +
  #next line turns y axis label ninety degrees and justifies
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

# RI_2B1_plot

# This is the bit that writes the fact table which is used to make the nice tables in the quarto report
RI_2B1_walk_cycle_rate_plot_tbl |>
  filter(mode_type == "Active Travel") |>
  select(period_start, period_end, value) |>
  build_fact("RI_2B1_walk_cycle_rate") |>
  save_fact()
