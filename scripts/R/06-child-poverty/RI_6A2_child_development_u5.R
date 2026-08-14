# libraries ---------------------
library(tidyverse)
library(janitor)
library(glue)
library(readxl)
library(here)
source(here::here("scripts", "R", "_common.R"))

# RI_6A2_good_development

# Getting data
RI_6A2_child_development_u5_path <- here::here(
  "data",
  "raw",
  "6.A.2-good_development_05.26.xlsx"
)

RI_6A2_child_development_u5_raw_tbl <- read_excel(
  RI_6A2_child_development_u5_path,
  sheet = "good_development",
  skip = 2
) |>
  rename(area = 1) |>
  mutate(
    area = str_squish(area),
    area = recode(
      area,
      "Bristol, City of" = "Bristol",
      "West of England +" = "West of England"
    )
  )

# Convert data from wide format, where years are columns,
RI_6A2_child_development_u5_long_tbl <-
  RI_6A2_child_development_u5_raw_tbl |>
  mutate(across(-area, as.character)) |>
  pivot_longer(
    cols = -area,
    names_to = "academic_year",
    values_to = "value"
  ) |>
  mutate(
    value = readr::parse_number(value)
  )

# Compare local authorities against the West of England average
RI_6A2_child_development_u5_plot_tbl <-
  RI_6A2_child_development_u5_long_tbl |>
  filter(
    academic_year >= "2015/16"
  ) |>
  filter(
    area %in%
      c(
        "Bath and North East Somerset",
        "Bristol",
        "North Somerset",
        "South Gloucestershire",
        "West of England"
      )
  )

# Line chart
RI_6A2_child_development_u5_plot <-
  RI_6A2_child_development_u5_plot_tbl |>
  ggplot(
    aes(
      x = academic_year,
      y = value,
      colour = area,
      group = area
    )
  ) +
  geom_line() +
  geom_point() +
  scale_colour_manual(
    values = c(
      ua_colors_by_name,
      "West of England" = "#40A832"
    )
  ) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    title = "Children achieving a good level of development",
    # subtitle = "West of England",
    x = "Academic year",
    y = NULL,
    colour = NULL,
    caption = "Source: Department for Education"
  ) +
  theme_ua() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5),
    axis.text.x = element_text(angle = 0, hjust = 0.5),
    legend.position = "bottom"
  ) +
  guides(
    colour = guide_legend(ncol = 2)
  )

# View line chart
RI_6A2_child_development_u5_plot

# Creating fact table
RI_6A2_child_development_u5_fact_tbl <-
  RI_6A2_child_development_u5_long_tbl |>
  filter(
    area == "West of England",
    academic_year >= "2015/16"
  ) |>
  mutate(
    start_year = readr::parse_number(academic_year),
    period_start = as.Date(glue("{start_year}-09-01")),
    period_end = as.Date(glue("{start_year + 1}-08-31")),
    value = value * 100
  ) |>
  select(
    period_start,
    period_end,
    value
  )

# Save the fact file
RI_6A2_child_development_u5_fact_tbl |>
  build_fact(
    indicator_id = "RI_6A2_child_development_u5"
  ) |>
  save_fact()
