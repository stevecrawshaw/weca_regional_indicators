# libraries ---------------------
library(tidyverse)
library(janitor)
library(readxl)
library(here)

source(here::here("scripts", "R", "_common.R"))

# RI_6B2_early_years_quality

# Getting data
RI_6B2_early_years_quality_path <- here::here(
  "data",
  "raw",
  "6.B.2_early_years_quality_06.26.xlsx"
)

RI_6B2_early_years_quality_raw_tbl <- read_excel(
  RI_6B2_early_years_quality_path,
  sheet = "Sheet1",
  skip = 4,
  col_types = c("date", "text", "numeric")
) |>
  clean_names() |>
  rename(
    value = outstanding_and_good
  ) |>
  mutate(
    area = str_squish(area),
    area = recode(
      area,
      "West of England+" = "West of England"
    )
  )

# Use local authorities and West of England for this line chart
# We just use the data for the August OFSTED assessment
RI_6B2_early_years_quality_plot_tbl <-
  RI_6B2_early_years_quality_raw_tbl |>
  filter(
    area %in%
      c(
        "Bath and North East Somerset",
        "Bristol",
        "North Somerset",
        "South Gloucestershire",
        "West of England"
      ),
    month(date) == 8
  )

# Line chart
RI_6B2_early_years_quality_plot <-
  RI_6B2_early_years_quality_plot_tbl |>
  ggplot(
    aes(
      x = date,
      y = value,
      colour = area,
      group = area
    )
  ) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_colour_manual(
    values = c(
      ua_colors_by_name,
      "West of England" = "#40A832"
    )
  ) +
  scale_y_continuous(
    labels = scales::label_number(suffix = "%")
  ) +
  scale_x_date(
    date_breaks = "1 year",
    date_labels = "%Y"
  ) +
  labs(
    title = "Early years settings judged good or outstanding",
    # subtitle = "West of England",
    x = "Date",
    y = NULL,
    colour = NULL,
    caption = "Source: Ofsted"
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
RI_6B2_early_years_quality_plot

# Creating fact table
RI_6B2_early_years_quality_fact_tbl <-
  RI_6B2_early_years_quality_plot_tbl |>
  filter(area == "West of England") |>
  mutate(
    period_start = make_date(year = year(date), 1, 1),
    period_end = make_date(year = year(date) + 1, 12, 31),
  ) |>
  select(
    period_start,
    period_end,
    value
  )

# Save the fact file
RI_6B2_early_years_quality_fact_tbl |>
  build_fact(
    indicator_id = "RI_6B2_early_years_quality"
  ) |>
  save_fact()
