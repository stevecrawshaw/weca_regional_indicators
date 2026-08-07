# libraries ---------------------
pacman::p_load(tidyverse, janitor, glue, tidyxl, readxl, here)
source(here::here("scripts", "R", "_common.R"))

# RI_4B3_neet_16_17

# Getting data
RI_4B3_neet_16_17_path <- here::here(
  "data",
  "raw",
  "4.B.3-neet_16-17_05.26.xlsx"
)

RI_4B3_neet_16_17_raw_tbl <- read_excel(
  RI_4B3_neet_16_17_path,
  sheet = "neet_16-17(RI)",
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
RI_4B3_neet_16_17_long_tbl <-
  RI_4B3_neet_16_17_raw_tbl |>
  pivot_longer(
    cols = -area,
    names_to = "year",
    values_to = "value"
  ) |>
  mutate(
    year = as.integer(year),
    value = as.numeric(value)
  )

glimpse(RI_4B3_neet_16_17_long_tbl)

# Filtering the areas & dates for the line chart
RI_4B3_neet_16_17_plot_tbl <-
  RI_4B3_neet_16_17_long_tbl |>
  filter(year >= 2015) |>
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
RI_4B3_neet_16_17_plot <-
  RI_4B3_neet_16_17_plot_tbl |>
  ggplot(aes(x = year, y = value, colour = area, group = area)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_colour_manual(
    values = c(
      ua_colors_by_name,
      "West of England" = "#40A832"
    )
  ) +
  scale_y_continuous(labels = scales::percent) +
  scale_x_continuous(breaks = seq(2019, 2025, by = 1)) +
  labs(
    title = "16 to 17 year olds not in education, employment or training",
    # subtitle = "West of England",
    x = "Year",
    y = "%",
    colour = NULL,
    caption = "Source: Department for Education"
  ) +
  theme_ua() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5),
    legend.position = "bottom"
  ) +
  guides(
    colour = guide_legend(ncol = 2)
  )

# Creating fact table
RI_4B3_neet_16_17_fact_tbl <-
  RI_4B3_neet_16_17_long_tbl |>
  filter(
    area == "West of England",
    year >= 2015
  ) |>
  mutate(
    period_start = as.Date(glue("{year}-01-01")),
    period_end = as.Date(glue("{year}-12-31")),
    value = value * 100
  ) |>
  select(
    period_start,
    period_end,
    value
  )


# Save the fact file
RI_4B3_neet_16_17_fact_tbl |>
  build_fact(
    indicator_id = "RI_4B3_neet_16_17"
  ) |>
  save_fact()
