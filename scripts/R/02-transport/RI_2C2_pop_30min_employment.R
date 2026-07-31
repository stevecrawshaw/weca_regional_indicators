library("tidyverse")
library("here")
library("janitor")
library("readxl")
library("glue")

source(here::here("scripts", "R", "_common.R"))

RI_2C2_pop_30min_employment <- read_excel(
  path = here("data", "raw", "Connectivity_Indicators.xlsx"),
  sheet = "30mins",
  skip = 3
) |>

  clean_names() |>

  mutate(
    period_start = as.Date(glue("{year}-01-01")),
    period_end = as.Date(glue("{year}-12-31"))
  ) |>
  select(period_start, period_end, x15_mins_st_5000, x30_mins_st_5000) |>
  # you have some NA values so need to add a filter condition so you only ingest valid data
  filter(!is.na(x30_mins_st_5000))


RI_2C2_pop_30min_employment_plot_tbl <- RI_2C2_pop_30min_employment |>
  select(period_start, period_end, x15_mins_st_5000, x30_mins_st_5000) |>

  pivot_longer(
    cols = c(x15_mins_st_5000, x30_mins_st_5000),
    names_to = "journey_time",
    values_to = "value"
  ) |>
  mutate(
    journey_time = case_when(
      journey_time == "x15_mins_st_5000" ~ "15 minutes",
      journey_time == "x30_mins_st_5000" ~ "30 minutes"
    )
  )


journey_time_colours <- weca_colors[1:2]

journey_time_colours_named <-
  journey_time_colours |>
  set_names("15 minutes", "30 minutes")

RI_2C2_plot <-
  RI_2C2_pop_30min_employment_plot_tbl |>
  ggplot(aes(x = period_start, y = value, fill = journey_time)) +
  geom_col(position = "dodge") +
  labs(
    title = "Population within 30 minutes of major employment sites",
    subtitle = "by bus, train, walking or cycling",
    x = "Year",
    y = "% of population",
    fill = "Journey time"
  ) +

  scale_fill_manual(values = journey_time_colours_named) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

# RI_2C2_plot

# This is the bit that writes the fact table which is used to make the nice tables in the quarto report
RI_2C2_pop_30min_employment_plot_tbl |>
  filter(journey_time == "30 minutes") |>
  select(period_start, period_end, value) |>
  build_fact("RI_2C2_pop_30min_employment") |>
  save_fact()
