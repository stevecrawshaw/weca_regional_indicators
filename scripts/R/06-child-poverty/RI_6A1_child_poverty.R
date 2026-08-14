# libraries ---------------------
pacman::p_load(tidyverse, janitor, glue, tidyxl, readxl, here)
source(here::here("scripts", "R", "_common.R"))

# RI_6A1_child_poverty

# Getting data
RI_6A1_child_poverty_path <- here::here(
  "data",
  "raw",
  "6.A.1-child_poverty_05.26.xlsx"
)

RI_6A1_child_poverty_raw_tbl <- read_excel(
  RI_6A1_child_poverty_path,
  sheet = "child_poverty%",
  skip = 2
) |>
  rename(area = 1) |>
  mutate(
    area = str_squish(area), #gets rid of spaces ect
    area = recode(
      area,
      "Bristol, City of" = "Bristol", #so it matches theme
      "West of England +" = "West of England"
    )
  )

# Turning year columns into rows
RI_6A1_child_poverty_long_tbl <-
  RI_6A1_child_poverty_raw_tbl |>
  mutate(across(-area, as.character)) |>
  pivot_longer(
    cols = -area,
    names_to = "academic_year",
    values_to = "value"
  ) |>
  mutate(
    value = readr::parse_number(value) #used parse as it has % in the datasheet
  )

# Filtering West of England & dates for the bar chart
RI_6A1_child_poverty_plot_tbl <-
  RI_6A1_child_poverty_long_tbl |>
  filter(
    area == "West of England",
    academic_year >= "2015/16"
  )

# Bar chart
RI_6A1_child_poverty_plot <-
  RI_6A1_child_poverty_plot_tbl |>
  ggplot(aes(x = academic_year, y = value)) +
  geom_col(fill = "#40A832") +
  scale_y_continuous(labels = scales::percent) +
  labs(
    title = "Children in poverty after housing costs",
    subtitle = "West of England",
    x = "Financial year",
    y = NULL,
    caption = "Source: End Child Poverty"
  ) +
  theme_weca() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# View bar chart
#RI_6A1_child_poverty_plot

# Creating fact table
RI_6A1_child_poverty_fact_tbl <-
  RI_6A1_child_poverty_long_tbl |>
  filter(
    area == "West of England",
    academic_year >= "2015/16"
  ) |>
  mutate(
    start_year = readr::parse_number(academic_year),
    period_start = as.Date(glue("{start_year}-04-01")),
    period_end = as.Date(glue("{start_year + 1}-03-31")),
    value = value * 100
  ) |>
  select(
    period_start,
    period_end,
    value
  )

# Save the fact file
RI_6A1_child_poverty_fact_tbl |>
  build_fact(
    indicator_id = "RI_6A1_child_poverty"
  ) |>
  save_fact()

