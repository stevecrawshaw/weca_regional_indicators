pacman::p_load(tidyverse, glue, janitor, here)
source(here::here("scripts", "R", "_common.R"))

# RI_1E2_population_change

RI_1E2_raw_tbl <- read_csv(
  here::here(
    "data",
    "raw",
    "pop_change_long_summary.csv"
  ),
  col_types = cols(
    Date = col_date(format = "%d/%m/%Y"),
    Area = col_character(),
    cumulative_percentage_change = col_double()
  )
)

# head(RI_1E2_raw_tbl)

RI_1E2_fact_tbl <- RI_1E2_raw_tbl |>
  filter(Area == "West of England") |>
  transmute(
    period_start = make_date(year(Date), 1, 1),
    period_end = make_date(year(Date), 12, 31),
    value = cumulative_percentage_change,
    Date = NULL,
    cumulative_percentage_change = NULL
  )
#plot

RI_1E2_plot <-
  RI_1E2_raw_tbl |>
  ggplot(
    aes(x = Date, y = cumulative_percentage_change, color = Area),
    na.rm = TRUE
  ) +
  geom_line() +
  geom_point() +
  scale_color_manual(
    values = c(
      "Bath & North East Somerset" = "#590075",
      "Bristol" = "#CE132D",
      "North Somerset" = "#ED8073",
      "South Gloucestershire" = "#1D4F2B",
      "West of England" = "#40A832"
    )
  ) +
  labs(
    title = "Cumulative Population change",
    subtitle = "West of England",
    y = "%",
    x = "Year",
    caption = "Source: ONS mid-year population estimates"
  ) +
  theme_weca() +
  theme(
    legend.title = element_blank(),
    legend.text = element_text(size = 11),
    axis.title.y = element_text(angle = 0, vjust = 0.5)
  ) +
  guides(color = guide_legend(nrow = 2)) +
  scale_x_date(
    date_breaks = "1 year",
    date_labels = "%Y"
  )

# RI_1E2_plot

#fact table

RI_1E2_fact_tbl |>
  build_fact("RI_1E2_population_change") |>
  save_fact()
