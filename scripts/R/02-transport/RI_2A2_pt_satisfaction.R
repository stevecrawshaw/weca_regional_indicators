library("tidyverse")
library("here")
library("janitor")
library("readxl")
library("glue")

source(here::here("scripts", "R", "_common.R"))

RI_2A2_pt_satisfaction <- read_excel(
  path = here("data", "raw", "Bus_Satisfaction.xlsx"),
  sheet = "Satisfaction",
  skip = 2
) |>

  clean_names() |>

  mutate(
    period_start = as.Date(glue("{year}-01-01")),
    period_end = as.Date(glue("{year}-12-31"))
  ) |>

  select(period_start, period_end, overall_satisfaction, satisfaction_england)

RI_2A2_pt_satisfaction_plot_tbl <- RI_2A2_pt_satisfaction |>
  select(
    period_start,
    period_end,
    overall_satisfaction,
    satisfaction_england
  ) |>

  pivot_longer(
    cols = c(overall_satisfaction, satisfaction_england),
    names_to = "satisfaction_type",
    values_to = "value"
  ) |>
  mutate(
    satisfaction_type = if_else(
      satisfaction_type == "overall_satisfaction",
      "West of England",
      "England"
    )
  )


satisfaction_colours <- weca_colors[1:2]

sat_colors_named <-
  satisfaction_colours |>
  set_names("West of England", "England")

RI_2A2_plot <-
  RI_2A2_pt_satisfaction_plot_tbl |>
  ggplot(aes(x = period_start, y = value, fill = satisfaction_type)) +
  geom_col(position = "dodge") +
  labs(
    title = "Public Transport Satisfaction",
    subtitle = "% of bus users satisfied",
    x = "Year",
    y = "%",
    fill = "Area"
  ) +

  scale_fill_manual(values = sat_colors_named) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

# RI_2A2_plot

RI_2A2_pt_satisfaction_plot_tbl |>
  filter(satisfaction_type == "West of England") |>
  select(period_start, period_end, value) |>
  build_fact("RI_2A2_pt_satisfaction") |>
  save_fact()
