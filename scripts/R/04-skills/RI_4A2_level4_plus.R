# libraries ---------------------
library(tidyverse)
library(here)
library(nomisdata)
library(lubridate)

source(here::here("scripts", "R", "_common.R"))

# RI_4A2_level4_plus

# Getting data from Nomis (you get all this data from the URL)
# Dataset: NM_17_5
# Variable: % with RQF4+ - aged 16-64
RI_4A2_level4_plus_raw_tbl <- fetch_nomis(
  id = "NM_17_5",
  geography = c(
    "1778384918", # Bath and North East Somerset
    "1778384919", # Bristol, City of
    "1778384920", # North Somerset
    "1778384921", # South Gloucestershire
    "1925185566", # West of England LEP
    "2092957699" # England
  ),
  # date = c(
  #   "latestMINUS40", "latestMINUS36", "latestMINUS32",
  #   "latestMINUS28", "latestMINUS24", "latestMINUS20",
  #   "latestMINUS16", "latestMINUS12", "latestMINUS8",
  #   "latestMINUS4", "latest"
  # ),
  date = paste0(2022:(year(Sys.Date()) - 1), "-12"),
  variable = 1902,
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
RI_4A2_level4_plus_long_tbl <-
  RI_4A2_level4_plus_raw_tbl |>
  transmute(
    area,

    # Nomis date is annual December data, e.g. Dec 2022.
    # We store this as the final day of that month.
    period_end = ceiling_date(ymd(paste0(date, "-01")), "month") - days(1),

    # Nomis returns percentages as whole numbers,
    # Divide by 100 so values are stored as proportions.
    value = obs_value / 100
  ) |>
  filter(
    # Data are only available from Dec 2022 for this variable,
    # so keep Dec 2022 onwards for charts and tables.
    period_end >= as.Date("2022-12-31")
  )


# Check to make sure each area should have one row per available year
# RI_4A2_level4_plus_long_tbl |>
#   count(area)

# Compare local authorities against West of England
RI_4A2_level4_plus_plot_tbl <-
  RI_4A2_level4_plus_long_tbl |>
  filter(
    area %in%
      c(
        "Bath and North East Somerset",
        "Bristol",
        "North Somerset",
        "South Gloucestershire",
        "West of England"
      )
  ) |>
  mutate(
    year = lubridate::year(period_end)
  )


# Line chart
RI_4A2_level4_plus_plot <-
  RI_4A2_level4_plus_plot_tbl |>
  ggplot(
    aes(
      x = year,
      y = value,
      colour = area,
      group = area
    )
  ) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_colour_manual(
    values = c(
      ua_colors_by_name,
      "West of England" = "#40A832"
    )
  ) +
  scale_x_continuous(
    breaks = seq(
      min(RI_4A2_level4_plus_plot_tbl$year),
      max(RI_4A2_level4_plus_plot_tbl$year),
      by = 1
    )
  ) +
  scale_y_continuous(
    labels = scales::label_percent(accuracy = 1)
  ) +
  labs(
    title = "Residents aged 16-64 with Level 4 or above qualifications",
    # subtitle = "West of England",
    x = "Year",
    y = NULL,
    colour = NULL,
    caption = "Source: Nomis, Annual Population Survey"
  ) +
  theme_ua() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5),
    legend.position = "bottom"
  ) +
  guides(
    colour = guide_legend(ncol = 2)
  )

# View line chart
# RI_4A2_level4_plus_plot

# Creating fact table
# This indicator is annual December data from Nomis.
RI_4A2_level4_plus_fact_tbl <-
  RI_4A2_level4_plus_long_tbl |>
  filter(
    area == "West of England"
  ) |>
  mutate(
    period_start = as.Date(glue("{year(period_end)}-01-01")),
    value = value * 100
  ) |>
  select(
    period_start,
    period_end,
    value
  )

# Save the fact file
RI_4A2_level4_plus_fact_tbl |>
  build_fact(
    indicator_id = "RI_4A2_level4_plus"
  ) |>
  save_fact()
