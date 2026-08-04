# libraries ---------------------
library(tidyverse)
library(janitor)
library(glue)
library(readxl)
library(here)

source(here::here("scripts", "R", "_common.R"))

# RI_6A3_ks2_expected_standards

# Getting data
RI_6A3_ks2_expected_standards_path <- here::here(
  "data",
  "raw",
  "6.A.3-ks2_expected_standards_05.26.xlsx"
)

RI_6A3_ks2_expected_standards_raw_tbl <- read_excel(
  RI_6A3_ks2_expected_standards_path,
  sheet = "Expected Standards KS2",
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
RI_6A3_ks2_expected_standards_long_tbl <-
  RI_6A3_ks2_expected_standards_raw_tbl |>
  mutate(across(-area, as.character)) |>
  pivot_longer(
    cols = -area,
    names_to = "academic_year",
    values_to = "value"
  ) |>
  mutate(
    value = readr::parse_number(value)
  )

# Use West of England only for this indicator chart
RI_6A3_ks2_expected_standards_plot_tbl <-
  RI_6A3_ks2_expected_standards_long_tbl |>
  filter(
    area == "West of England",
    academic_year >= "2015/16"
  )

# Bar chart
RI_6A3_ks2_expected_standards_plot <-
  RI_6A3_ks2_expected_standards_plot_tbl |>
  ggplot(aes(x = academic_year, y = value)) +
  geom_col(fill = "#40A832") +
  scale_y_continuous(labels = scales::percent) +
  labs(
    title = "Pupils meeting expected standards in reading, writing \nand maths at KS2",
    subtitle = "West of England",
    x = "Academic year",
    y = "%",
    caption = "Source: Department for Education"
  ) +
  theme_weca() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# View bar chart
#RI_6A3_ks2_expected_standards_plot

# Creating fact table
RI_6A3_ks2_expected_standards_fact_tbl <-
  RI_6A3_ks2_expected_standards_long_tbl |>
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
  ) |>
  filter(!is.na(value))

# Save the fact file
RI_6A3_ks2_expected_standards_fact_tbl |>
  build_fact(
    indicator_id = "RI_6A3_ks2_expected_standards"
  ) |>
  save_fact()
