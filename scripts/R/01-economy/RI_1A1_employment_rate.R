# libraries ---------------------
pacman::p_load(tidyverse, janitor, glue, here, nomisdata, lubridate)

source(here::here("scripts", "R", "_common.R"))

# RI_1A1_employment_rate
# This was moved from the skills priority into economy

# Getting data from Nomis
# Dataset: NM_17_5
# Variable: Employment rate - aged 16-64
RI_1A1_employment_rate_raw_tbl <- fetch_nomis(
  id = "NM_17_5",
  geography = c(
    "1778384918", # Bath and North East Somerset
    "1778384919", # Bristol, City of
    "1778384920", # North Somerset
    "1778384921", # South Gloucestershire
    "1925185566", # West of England LEP
    "2092957699", # England
    "2092957698" # Great Britain
  ),
  date = "latestMINUS43-latest",
  variable = 45,
  measures = 20599
) |>
  clean_names() |>
  mutate(
    # Clean area names so they match the rest of the Regional Indicators project
    area = str_squish(geography_name),
    area = recode(
      area,
      "Bristol, City of" = "Bristol",
      "West of England LEP" = "West of England"
    )
  )

# Keep the columns needed for plotting, checking and the fact table
RI_1A1_employment_rate_long_tbl <-
  RI_1A1_employment_rate_raw_tbl |>
  transmute(
    area,
    period_end = ceiling_date(ymd(paste0(date, "-01")), "month") - days(1),
    period_start = floor_date(period_end %m-% months(11), "month"),
    value = obs_value / 100
  )


# Check each area has one row per available period
RI_1A1_employment_rate_long_tbl |>
  count(area)

# Chart table: West of England and Great Britain only
RI_1A1_employment_rate_plot_tbl <-
  RI_1A1_employment_rate_long_tbl |>
  filter(
    area %in%
      c(
        "West of England",
        "Great Britain"
      )
  )


# Line chart
RI_1A1_employment_rate_plot <-
  RI_1A1_employment_rate_plot_tbl |>
  ggplot(
    aes(
      x = period_end,
      y = value,
      colour = area,
      group = area
    )
  ) +
  geom_line() +
  geom_point() +
  scale_colour_manual(
    values = c(
      "West of England" = "#40A832",
      "Great Britain" = "grey40"
    )
  ) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(
    labels = scales::label_percent(accuracy = 1),
    breaks = seq(0, 1, by = 0.01)
  ) +
  labs(
    title = "Employment rate for residents aged 16-64",
    subtitle = "West of England and Great Britain",
    x = "Year",
    y = "Employment \nrate",
    colour = NULL,
    caption = "Source: Nomis, Annual Population Survey"
  ) +
  theme_ua() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5)
  )


# Creating fact table
RI_1A1_employment_rate_fact_tbl <-
  RI_1A1_employment_rate_long_tbl |>
  filter(
    area == "West of England"
  ) |>
  mutate(
    value = value * 100
  ) |>
  select(
    period_start,
    period_end,
    value
  )

# Save the fact file
RI_1A1_employment_rate_fact_tbl |>
  build_fact(
    indicator_id = "RI_1A1_employment_rate"
  ) |>
  save_fact()
