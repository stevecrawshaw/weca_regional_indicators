# libraries ---------------------
library(tidyverse)
library(readxl)
library(here)
source(here::here("scripts", "R", "_common.R"))

# RI_6B1_childcare_places

# Getting data
RI_6B1_childcare_places_path <- here::here(
  "data",
  "raw",
  "6.B.1_childcare_places_06.26.xlsx"
)

RI_6B1_childcare_places_raw_tbl <- read_excel(
  RI_6B1_childcare_places_path,
  sheet = "childcare_places",
  skip = 3,
  col_types = c("date", "text", "numeric", "numeric", "numeric")
) |>
  clean_names() |>
  rename(
    value = proportion
  ) |>
  mutate(
    area = str_squish(area),
    area = recode(
      area,
      "West of England+" = "West of England"
    )
  )

# Use West of England only for this indicator chart
# And just the August Ofsted ratings
RI_6B1_childcare_places_plot_tbl <-
  RI_6B1_childcare_places_raw_tbl |>
  filter(area == "West of England", month(date) == 8)

# Line chart
RI_6B1_childcare_places_plot <-
  RI_6B1_childcare_places_plot_tbl |>
  ggplot(aes(x = date, y = value)) +
  geom_line(linewidth = 1.2, colour = "#40A832") +
  geom_point(size = 3, colour = "#40A832") +
  scale_y_continuous(labels = scales::percent) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(
    title = "Childcare places relative to population aged 0 to 4",
    subtitle = "West of England",
    x = "Year",
    y = NULL,
    caption = "Source: Ofsted and ONS"
  ) +
  theme_weca() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5)
  )

# View line chart
# RI_6B1_childcare_places_plot

# Creating fact table

RI_6B1_childcare_places_fact_tbl <-
  RI_6B1_childcare_places_plot_tbl |>
  filter(area == "West of England") |>
  mutate(
    period_start = make_date(year = year(date), 1, 1),
    period_end = make_date(year = year(date) + 1, 12, 31),
    value = value * 100
  ) |>
  select(
    period_start,
    period_end,
    value
  )

# Save the fact file
RI_6B1_childcare_places_fact_tbl |>
  build_fact(
    indicator_id = "RI_6B1_childcare_places"
  ) |>
  save_fact()
