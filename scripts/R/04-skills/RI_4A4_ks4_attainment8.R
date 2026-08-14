# libraries ---------------------
pacman::p_load(tidyverse, janitor, glue, tidyxl, readxl, here)
source(here::here("scripts", "R", "_common.R"))

# RI_4A4_ks4_attainment8

# Getting data
RI_4A4_ks4_attainment8_path <- here::here(
  "data",
  "raw",
  "4.A.4-attainment8_05.26.xlsx"
)

RI_4A4_ks4_attainment8_raw_tbl <- read_excel(
  RI_4A4_ks4_attainment8_path,
  sheet = "attainment8",
  skip = 2
) |>
  rename(area = 1) |>
  mutate(
    area = str_squish(area),
    area = recode(
      area,
      "Bristol, City of" = "Bristol",
      "West of England LEP" = "West of England"
    )
  )

# Turning year columns into rows
RI_4A4_ks4_attainment8_long_tbl <-
  RI_4A4_ks4_attainment8_raw_tbl |>
  pivot_longer(
    cols = -area,
    names_to = "academic_year",
    values_to = "value"
  ) |>
  mutate(
    value = as.numeric(value)
  )


# Filtering the areas & dates for the line chart
RI_4A4_ks4_attainment8_plot_tbl <-
  RI_4A4_ks4_attainment8_long_tbl |>
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
RI_4A4_ks4_attainment8_plot <-
  RI_4A4_ks4_attainment8_plot_tbl |>
  ggplot(aes(x = academic_year, y = value, colour = area, group = area)) +
  geom_line() +
  geom_point() +
  scale_colour_manual(
    values = c(
      ua_colors_by_name,
      "West of England" = "#40A832"
    )
  ) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Attainment 8 score",
    # subtitle = "West of England",
    x = "Academic year",
    y = "Attainment\n8 score",
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


# Creating fact table
RI_4A4_ks4_attainment8_fact_tbl <-
  RI_4A4_ks4_attainment8_long_tbl |>
  filter(
    area == "West of England",
    academic_year >= "2015/16"
  ) |>
  mutate(
    start_year = readr::parse_number(academic_year),
    period_start = as.Date(glue("{start_year}-08-01")),
    period_end = as.Date(glue("{start_year + 1}-07-31"))
  ) |>
  select(
    period_start,
    period_end,
    value
  )


# Save the fact file
RI_4A4_ks4_attainment8_fact_tbl |>
  build_fact(
    indicator_id = "RI_4A4_ks4_attainment8"
  ) |>
  save_fact()
