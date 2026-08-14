# libraries ---------------------
pacman::p_load(tidyverse, janitor, glue, fingertipsR, here)
source(here::here("scripts", "R", "_common.R"))

# RI_6D2_life_expectancy_gap
# Inequality in life expectancy at birth

# Getting data ------------------
RI_6D2_life_expectancy_gap_raw_tbl <- fingertips_data(
  IndicatorID = 92901,
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

# Clean and filter data ----------
RI_6D2_life_expectancy_gap_plot_tbl <-
  RI_6D2_life_expectancy_gap_raw_tbl |>
  filter(
    area_name %in% c(
      "Bath and North East Somerset",
      "Bristol",
      "North Somerset",
      "South Gloucestershire"
    ),
    sex %in% c("Male", "Female"),
    timeperiod_sortable >= 20150000
  ) |>
  transmute(
    area = area_name,
    sex,
    timeperiod,
    timeperiod_sortable,
    value,
    lower_ci95_0limit,
    upper_ci95_0limit
  ) |>
  arrange(sex, area, timeperiod_sortable)

# Male chart ---------------------
RI_6D2_life_expectancy_gap_male_plot <-
  RI_6D2_life_expectancy_gap_plot_tbl |>
  filter(
    sex == "Male"
  ) |>
  ggplot(
    aes(
      x = timeperiod,
      y = value,
      colour = area,
      group = area
    )
  ) +
  geom_line() +
  geom_point() +
  scale_colour_manual(
    values = ua_colors_by_name
  ) +
  scale_y_continuous(
    breaks = seq(0, 14, by = 2)
  ) +
  coord_cartesian(
    ylim = c(0, 14)
  ) +
  labs(
    title = "Male inequality in life expectancy at birth",
    x = "Time period",
    y = "Gap in \nyears",
    colour = NULL,
    caption = "Source: Fingertips"
  ) +
  theme_ua() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  ) +
  guides(
    colour = guide_legend(ncol = 2)
  )

# Female chart -------------------
RI_6D2_life_expectancy_gap_female_plot <-
  RI_6D2_life_expectancy_gap_plot_tbl |>
  filter(
    sex == "Female"
  ) |>
  ggplot(
    aes(
      x = timeperiod,
      y = value,
      colour = area,
      group = area
    )
  ) +
  geom_line() +
  geom_point() +
  scale_colour_manual(
    values = ua_colors_by_name
  ) +
  scale_y_continuous(
    breaks = seq(0, 14, by = 2)
  ) +
  coord_cartesian(
    ylim = c(0, 14)
  ) +
  labs(
    title = "Female inequality in life expectancy at birth",
    x = "Time period",
    y = "Gap in \nyears",
    colour = NULL,
    caption = "Source: Fingertips"
  ) +
  theme_ua() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  ) +
  guides(
    colour = guide_legend(ncol = 2)
  )
