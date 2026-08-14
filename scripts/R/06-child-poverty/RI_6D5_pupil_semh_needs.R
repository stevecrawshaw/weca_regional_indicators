# libraries ---------------------
pacman::p_load(tidyverse, janitor, glue, fingertipsR, here)
source(here::here("scripts", "R", "_common.R"))

# RI_6D5_pupil_semh_needs
# Proportion of school pupils with social, emotional and mental health needs

# Getting data ------------------
RI_6D5_pupil_semh_needs_raw_tbl <- fingertips_data(
  IndicatorID = 91871,
  AreaTypeID = 502
) |>
  clean_names() |>
  mutate(
    area_name = str_squish(area_name),
    area_name = recode(
      area_name,
      "Bristol, City of" = "Bristol"
    )
  )

# Keep required areas -----------
RI_6D5_pupil_semh_needs_la_tbl <-
  RI_6D5_pupil_semh_needs_raw_tbl |>
  filter(
    age == "School age",
    area_name %in%
      c(
        "Bath and North East Somerset",
        "Bristol",
        "North Somerset",
        "South Gloucestershire",
        "England"
      )
  ) |>
  transmute(
    area = area_name,
    academic_year = timeperiod,
    timeperiod_sortable,
    count,
    denominator,
    value = value / 100
  )


# Create West of England figure --
RI_6D5_pupil_semh_needs_woe_tbl <-
  RI_6D5_pupil_semh_needs_la_tbl |>
  filter(
    area %in% c(
      "Bath and North East Somerset",
      "Bristol",
      "North Somerset",
      "South Gloucestershire"
    )
  ) |>
  group_by(academic_year, timeperiod_sortable) |>
  summarise(
    count = sum(count, na.rm = TRUE),
    denominator = sum(denominator, na.rm = TRUE),
    value = count / denominator,
    .groups = "drop"
  ) |>
  mutate(
    area = "West of England"
  ) |>
  select(
    area,
    academic_year,
    timeperiod_sortable,
    count,
    denominator,
    value
  )

# Combined table ----------------
RI_6D5_pupil_semh_needs_plot_tbl <-
  bind_rows(
    RI_6D5_pupil_semh_needs_la_tbl,
    RI_6D5_pupil_semh_needs_woe_tbl
  ) |>
  arrange(timeperiod_sortable, area)


# Bar chart ---------------------
RI_6D5_pupil_semh_needs_plot <-
  RI_6D5_pupil_semh_needs_woe_tbl |>
  ggplot(
    aes(
      x = academic_year,
      y = value
    )
  ) +
  geom_col(
    fill = "#40A832"
  ) +
  scale_y_continuous(
    labels = scales::percent
  ) +
  labs(
    title = "School pupils with social, emotional and mental health needs",
    subtitle = "West of England",
    x = "Academic year",
    y = NULL,
    caption = "Source: Fingertips"
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

# Creating fact table ------------
RI_6D5_pupil_semh_needs_fact_tbl <-
  RI_6D5_pupil_semh_needs_woe_tbl |>
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

# Save the fact file -------------
RI_6D5_pupil_semh_needs_fact_tbl |>
  build_fact(
    indicator_id = "RI_6D5_pupil_semh_needs"
  ) |>
  save_fact()

