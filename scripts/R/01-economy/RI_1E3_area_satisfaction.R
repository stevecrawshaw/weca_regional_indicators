library(tidyverse)
library(here)

source(here::here("scripts", "R", "_common.R"))

# RI_1E3_area_satisfaction

RI_1E3_raw_tbl <- read_csv(
  here::here(
    "data",
    "raw",
    "community life",
    "community_life_time_series.csv"
  ),
  col_types = cols(
    date = col_date(format = "%d/%m/%Y"),
    area = col_character(),
    percent_satisfied = col_double()
  )
)

#plot

RI_1E3_plot <- ggplot(RI_1E3_raw_tbl, aes(x = date)) +
  geom_line(
    aes(y = percent_satisfied, color = area),
    na.rm = TRUE
  ) +
  geom_point(aes(y = percent_satisfied, color = area), na.rm = TRUE) +
  scale_color_manual(
    values = c(
      "Bath & North East Somerset" = "#590075",
      "Bristol" = "#CE132D",
      "North Somerset" = "#ED8073",
      "South Gloucestershire" = "#1D4F2B"
    )
  ) +
  labs(
    title = "Satisfaction with local area as a place to live",
    subtitle = "Percentage of respondents satisfied, by unitary authority",
    y = NULL,
    x = "Year",
    caption = "Source: Community Life Survey (Department for Culture, Media and Sport)"
  ) +
  scale_x_date(
    date_breaks = "1 year",
    date_labels = "%Y"
  ) +
  scale_y_continuous(
    labels = scales::label_percent(accuracy = 0.1, scale = 1)
  ) +
  theme_weca() +
  theme(legend.title = element_blank(), legend.text = element_text(size = 11))

RI_1E3_plot

#fact table
# Bristol only because of weighting issues - noted in the
# text above fact table
RI_1E3_fact_tbl <- RI_1E3_raw_tbl |>
  filter(area == "Bristol") |>
  transmute(
    period_start = make_date(year(date), 1, 1),
    period_end = make_date(year(date), 12, 31),
    value = percent_satisfied,
    date = NULL,
    percent_satisfied = NULL
  )

RI_1E3_fact_tbl |>
  build_fact("RI_1E3_area_satisfaction") |>
  save_fact()
