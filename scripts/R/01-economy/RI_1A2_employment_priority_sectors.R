# libraries ---------------------
pacman::p_load(tidyverse, janitor, glue, here, lubridate)
source(here::here("scripts", "R", "_common.R"))

# RI_1A2_employment_priority_sectors

# Priority sector SIC codes
priority_sector_sic_codes <- c(
  "20", "254", "26", "27", "28", "29", "30",
  "3212", "3316", "465",
  "58", "59", "60", "61", "62", "63",
  "7021", "7111", "7112", "712", "721",
  "731", "741", "742", "743",
  "8552", "90", "9101", "9102", "951"
)

# Getting data ------------------
RI_1A2_employment_priority_sectors_path <- here::here(
  "data",
  "raw",
  "RI_1A2_employment_priority_sectors.csv"
)

RI_1A2_employment_priority_sectors_raw_tbl <- read_csv(
  RI_1A2_employment_priority_sectors_path
) |>
  clean_names() |>
  mutate(
    area = str_squish(geography_name),
    area = recode(
      area,
      "West of England LEP" = "West of England"
    ),
    industry_code = as.character(industry_code)
  )

# Keep priority sector SIC codes and aggregate employment
RI_1A2_employment_priority_sectors_long_tbl <-
  RI_1A2_employment_priority_sectors_raw_tbl |>
  filter(
    industry_code %in% priority_sector_sic_codes
  ) |>
  mutate(
    year = as.integer(date_name)
  ) |>
  filter(
    year >= 2015
  ) |>
  group_by(
    area,
    year
  ) |>
  summarise(
    value = sum(obs_value, na.rm = TRUE),
    .groups = "drop"
  )

## view(RI_1A2_employment_priority_sectors_long_tbl)

RI_1A2_employment_priority_sectors_fact_tbl <- RI_1A2_employment_priority_sectors_long_tbl |> 
  mutate(
    period_start = as.Date(glue("{year}-01-01")),
    period_end = as.Date(glue("{year}-12-31"))
  ) |> 
  select(
    period_start,
    period_end,
    value
  ) |>
  build_fact(
    indicator_id = "RI_1A2_employment_priority_sectors"
  ) |>
  save_fact()

## view(RI_1A2_employment_priority_sectors_long_tbl)



# Line chart
RI_1A2_employment_priority_sectors_plot <-
  RI_1A2_employment_priority_sectors_long_tbl |>
  ggplot(
    aes(
      x = year,
      y = value
    )
  ) +
  geom_line(
    linewidth = 1.2
  ) +
  geom_point(
    size = 2
  ) +
  scale_x_continuous(
    breaks = seq(
      min(RI_1A2_employment_priority_sectors_long_tbl$year),
      max(RI_1A2_employment_priority_sectors_long_tbl$year),
      by = 1
    )
  ) +
  scale_y_continuous(
    labels = scales::comma,
    n.breaks = 10
  ) +
  labs(
    title = "Employment in priority sectors (excluding clean energy)",
    subtitle = "West of England",
    x = NULL,
    y = "Employment",
    caption = "Source: Nomis BRES"
  ) +
  theme_ua() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5)
  )

# View chart
##RI_1A2_employment_priority_sectors_plot

