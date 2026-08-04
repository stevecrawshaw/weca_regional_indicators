library("tidyverse")
library("here")
library("janitor")
library("readxl")
library("glue")

source(here::here("scripts", "R", "_common.R"))

RI_2D2_bus_value_for_money <- read_excel(
  path = here("data", "raw", "Bus_Satisfaction.xlsx"),
  sheet = "ValueforMoney",
  skip = 2
) |>

  clean_names() |>

  mutate(
    period_start = as.Date(glue("{year}-01-01")),
    period_end = as.Date(glue("{year}-12-31"))
  ) |>
  # make_date(year,12,31)

  select(
    period_start,
    period_end,
    west_of_england,
    england,
    bristol,
    banes,
    ns,
    sgc
  )

RI_2D2_bus_value_for_money_plot_tbl <- RI_2D2_bus_value_for_money |>
  select(
    period_start,
    period_end,
    west_of_england,
    england,
    bristol,
    banes,
    ns,
    sgc
  ) |>

  pivot_longer(
    cols = c(west_of_england, england, bristol, banes, ns, sgc),
    names_to = "area",
    values_to = "value"
  ) |>
  mutate(
    area = case_when(
      area == "west_of_england" ~ "West of England",
      area == "england" ~ "England",
      area == "bristol" ~ "Bristol",
      area == "banes" ~ "B&NES",
      area == "ns" ~ "North Somerset",
      area == "sgc" ~ "South Glos"
    )
  )

# at_satisfaction_colours <- weca_colors[1:6]

# at_sat_colours_named <-
#   at_satisfaction_colours |>
#   set_names(
#     "West of England",
#     "England",
#     "Bristol",
#     "B&NES",
#     "North Somerset",
#     "South Glos"
#   )

at_sat_colours_named <- c(
  "West of England" = get_weca_color("west_green"),
  "England" = get_weca_color("black"),
  "Bristol" = get_weca_color("claret"),
  "B&NES" = get_weca_color("rich_purple"),
  "North Somerset" = get_weca_color("soft_purple"),
  "South Glos" = get_weca_color("forest_green")
)

RI_2D2_plot <-
  RI_2D2_bus_value_for_money_plot_tbl |>
  ggplot(aes(
    x = period_start,
    y = value,
    fill = fct_relevel(
      area,
      c(
        "B&NES",
        "Bristol",
        "North Somerset",
        "South Glos",
        "West of England",
        "England"
      )
    )
  )) +
  geom_col(position = "dodge") +
  labs(
    title = "Satisfaction with Value for Money",
    subtitle = "% of bus users satisfied",
    x = "Year",
    y = "%",
    fill = "Area"
  ) +

  scale_fill_manual(values = at_sat_colours_named) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))


RI_2D2_plot

RI_2D2_bus_value_for_money_plot_tbl |>
  filter(area == "West of England") |>
  select(period_start, period_end, value) |>
  build_fact("RI_2D2_bus_value_for_money") |>
  save_fact()
