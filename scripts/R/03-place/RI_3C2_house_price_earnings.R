# libraries ---------------------
library(tidyverse)
library(readxl)
library(janitor)
library(lubridate)
library(here)
library(glue)

source(here::here("scripts", "R", "_common.R"))

# ------------------------------------------------------------
# RI_3C2 – Price to Earnings Ratio (LA time series)
# ------------------------------------------------------------

path_3C2 <- here::here("data", "raw", "3C2.xlsx")
# same issue as RI_3A1 - by default read_excel() will read from the first line
# which is mostly empty. specify the range
RI_3C2_raw_tbl <- read_excel(path_3C2, sheet = 1, range = "A2:AF6") |>
  clean_names()

# Expecting columns:
# country_region_code, country_region_name, local_authority_code,
# local_authority_name, 1997, 1998, ..., 2024, five_year_average

# ^^^ R will not accept numbers as column headings
# so it will prefix these with "x" like "x2021"

# In this table  - and subsequent operations you are
# going back to 1997 - 28 years. We're generally using 10 years
# unless there is a genuinely compelling case for going back further
# Long time series will make your plots too dense and risk losing emphasis
# on the recent values.

# you could filter for only dates after the maximum date - 10 years
# where you use the filter for !is.na(period_start...)

RI_3C2_long_tbl <- RI_3C2_raw_tbl |>
  pivot_longer(
    # and hence your regex in the next line will fail because the pattern doesn't match
    # cols = matches("^\\d{4}$"),

    # You can use starts_with() to select all the columns that start
    # with x. A nice efficient helper.
    # https://tidyselect.r-lib.org/reference/index.html

    cols = starts_with("x"),
    names_to = "year_raw",
    values_to = "value"
  ) |>
  mutate(
    # again - as.integer("x2021") will fail so you need to remove "x" first
    # year = as.integer(year_raw),
    year = str_remove(year_raw, "x") |> as.integer(),

    area = recode(
      local_authority_name,
      # this won't stop your code from running but you are unnecessarily recoding
      # 3 values here which don't need recoding - they are identical
      #      "Bath and North East Somerset" = "Bath and North East Somerset",
      "Bristol, City of" = "Bristol",
      #      "North Somerset" = "North Somerset",
      #      "South Gloucestershire" = "South Gloucestershire"
    ),

    period_end = make_date(year, 12, 31),
    period_start = make_date(year, 1, 1)
  ) |>
  filter(!is.na(period_start), !is.na(period_end)) |>
  select(area, period_start, period_end, value)

max_date <- max(RI_3C2_long_tbl$period_start)
start_date <- max_date - years(9)
# ------------------------------------------------------------
# WECA aggregation
# ------------------------------------------------------------

RI_3C2_weca_tbl <- RI_3C2_long_tbl |>
  group_by(period_start, period_end) |>
  summarise(
    value = mean(value, na.rm = TRUE),
    area = "West of England",
    .groups = "drop"
  ) |>
  filter(period_start >= start_date)

RI_3C2_plot_tbl <- bind_rows(RI_3C2_long_tbl, RI_3C2_weca_tbl) |>
  filter(period_start >= start_date)
# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------

RI_3C2_plot <- RI_3C2_plot_tbl |>
  mutate(year = year(period_end)) |>
  ggplot(aes(x = year, y = value, colour = area, group = area)) +
  geom_line() +
  geom_point() +
  scale_colour_manual(
    values = c(
      ua_colors_by_name,
      "West of England" = "#40A832"
    )
  ) +
  scale_x_continuous(
    breaks = sort(unique(year(RI_3C2_plot_tbl$period_end)))
  ) +
  labs(
    title = "House Price to Earnings Ratio",
    subtitle = "Median workplace-based affordability ratio",
    x = "Year",
    y = "Ratio",
    colour = NULL,
    caption = "Source: ONS Housing Affordability Statistics"
  ) +
  theme_ua() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5),
    legend.position = "bottom"
  ) +
  guides(colour = guide_legend(ncol = 2))

# ------------------------------------------------------------
# Fact table
# ------------------------------------------------------------

RI_3C2_fact_tbl <- RI_3C2_weca_tbl |>
  select(period_start, period_end, value)

RI_3C2_fact_tbl |>
  build_fact(indicator_id = "RI_3C2_house_price_earnings") |>
  save_fact()
