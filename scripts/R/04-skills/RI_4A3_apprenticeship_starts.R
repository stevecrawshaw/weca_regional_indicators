# libraries
pacman::p_load(tidyverse, janitor, glue, tidyxl, readxl, here)


source(here::here("scripts", "R", "_common.R"))

# RI_4A3_apprenticeship_starts
# Getting data
RI_4A3_apprenticeship_starts_path <-
  here::here(
    "data",
    "raw",
    "4.A.3-data_apprenticeships_starts_05.26.xlsx"
  )

RI_4A3_apprenticeship_starts_raw_tbl <-
  read_excel(
    RI_4A3_apprenticeship_starts_path,
    sheet = "app_starts(RI)",
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
RI_4A3_apprenticeship_starts_long_tbl <-
  RI_4A3_apprenticeship_starts_raw_tbl |>
  pivot_longer(
    cols = -area,
    names_to = "academic_year",
    values_to = "value"
  ) |>
  mutate(
    value = as.numeric(value),
    start_year = readr::parse_number(academic_year)
  )

# Filtering local authorities and dates for stacked chart
RI_4A3_apprenticeship_starts_plot_tbl <-
  RI_4A3_apprenticeship_starts_long_tbl |>
  filter(
    start_year >= 2015,
    area %in%
      c(
        "Bath and North East Somerset",
        "Bristol",
        "North Somerset",
        "South Gloucestershire"
      )
  )


# Stacked bar chart
RI_4A3_apprenticeship_starts_plot <-
  RI_4A3_apprenticeship_starts_plot_tbl |>
  ggplot(
    aes(
      x = academic_year,
      y = value,
      fill = area
    )
  ) +
  geom_col() +
  scale_fill_manual(
    values = ua_colors_by_name
  ) +
  scale_y_continuous(
    labels = scales::comma
  ) +
  labs(
    title = "Apprenticeship starts",
    subtitle = "West of England",
    x = "Academic year",
    y = "Number\nof starts",
    fill = NULL,
    caption = "Source: Department for Education"
  ) +
  theme_ua() +
  theme(
    axis.title.y = element_text(
      angle = 0,
      vjust = 0.5
    ),
    axis.text.x = element_text(
      angle = 45,
      hjust = 1
    ),
    legend.position = "bottom"
  ) +
  guides(
    fill = guide_legend(
      ncol = 2
    )
  )

# Calculating change from the previous year
RI_4A3_apprenticeship_starts_change_tbl <-
  RI_4A3_apprenticeship_starts_long_tbl |>
  arrange(
    area,
    start_year
  ) |>
  group_by(area) |>
  mutate(
    previous_year_value = lag(value),
    annual_change = ((value - previous_year_value) /
      previous_year_value) *
      100
  ) |>
  ungroup()


# Filtering West of England for line chart
RI_4A3_apprenticeship_starts_change_plot_tbl <-
  RI_4A3_apprenticeship_starts_change_tbl |>
  filter(
    area == "West of England",
    start_year >= 2016,
    !is.na(annual_change)
  )


# Line chart showing annual change
RI_4A3_apprenticeship_starts_change_plot <-
  RI_4A3_apprenticeship_starts_change_plot_tbl |>
  ggplot(
    aes(x = academic_year, y = annual_change, group = 1)
  ) +
  geom_hline(
    yintercept = 0,
    colour = "grey70",
    linewidth = 0.5
  ) +
  geom_line(colour = "#40A832", linewidth = 1.2) +
  geom_point(colour = "#40A832", size = 2.5) +
  scale_y_continuous(
    breaks = seq(-40, 40, by = 4),
    labels = scales::label_percent(
      scale = 1,
      accuracy = 1
    )
  ) +
  labs(
    title = "Change in apprenticeship starts from the previous year",
    # subtitle = "West of England",
    x = "Academic year",
    y = "% Annual\nchange",
    caption = "Source: Department for Education"
  ) +
  theme_ua() +
  theme(
    axis.title.y = element_text(
      angle = 0,
      vjust = 0.5
    ),
    axis.text.x = element_text(
      angle = 45,
      hjust = 1
    )
  )


# Creating fact table

RI_4A3_apprenticeship_starts_fact_tbl <-
  RI_4A3_apprenticeship_starts_change_tbl |>
  filter(
    area == "West of England",
    start_year >= 2016,
    !is.na(annual_change)
  ) |>
  mutate(
    period_start = as.Date(
      glue("{start_year}-08-01")
    ),
    period_end = as.Date(
      glue("{start_year + 1}-07-31")
    ),
    value = round(
      annual_change,
      1
    )
  ) |>
  select(
    period_start,
    period_end,
    value
  )

# Save the fact file

RI_4A3_apprenticeship_starts_fact_tbl |>
  build_fact(
    indicator_id = "RI_4A3_apprenticeship_starts"
  ) |>
  save_fact()
