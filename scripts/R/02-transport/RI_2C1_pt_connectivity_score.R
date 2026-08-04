library("tidyverse")
library("here")
library("janitor")
library("readxl")
library("glue")

source(here::here("scripts", "R", "_common.R"))

RI_2C1_pt_connectivity_score <- read_excel(
  path = here("data", "raw", "Connectivity_Indicators.xlsx"),
  sheet = "Connectivity",
  skip = 1
) |>

  clean_names() |>

  mutate(
    period_start = as.Date(glue("{year}-01-01")),
    period_end = as.Date(glue("{year}-12-31"))
  ) |>

  select(
    period_start,
    period_end,
    wof_e_score,
    banes_connectivity,
    bristol_connectivity,
    ns_connectivity,
    sgc_connectivity
  ) |>

  filter(!is.na(wof_e_score))

RI_2C1_pt_connectivity_plot_tbl <- RI_2C1_pt_connectivity_score |>
  select(
    period_start,
    period_end,
    wof_e_score,
    banes_connectivity,
    bristol_connectivity,
    ns_connectivity,
    sgc_connectivity
  ) |>

  pivot_longer(
    cols = c(
      wof_e_score,
      banes_connectivity,
      bristol_connectivity,
      ns_connectivity,
      sgc_connectivity
    ),
    names_to = "area",
    values_to = "value"
  ) |>
  mutate(
    area = case_when(
      area == "wof_e_score" ~ "West of England",
      area == "banes_connectivity" ~ "B&NES",
      area == "bristol_connectivity" ~ "Bristol",
      area == "ns_connectivity" ~ "North Somerset",
      area == "sgc_connectivity" ~ "South Glos"
    )
  )

connectivity_colours_named <- c(
  "West of England" = get_weca_color("west_green"),
  "Bristol" = get_weca_color("claret"),
  "B&NES" = get_weca_color("rich_purple"),
  "North Somerset" = get_weca_color("soft_purple"),
  "South Glos" = get_weca_color("forest_green")
)


RI_2C1_plot <-
  RI_2C1_pt_connectivity_plot_tbl |>
  ggplot(aes(x = period_start, y = value, fill = area)) +
  geom_col(position = "dodge") +
  labs(
    title = "Public Transport Connectivity Score",
    subtitle = "Peak hour journey times by public transport to education, employment, retail and health",
    x = "Year",
    y = "Score",
    fill = "Area"
  ) +

  scale_fill_manual(values = connectivity_colours_named) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

# RI_2C1_plot

RI_2C1_pt_connectivity_plot_tbl |>
  filter(area == "West of England") |>
  select(period_start, period_end, value) |>
  build_fact("RI_2C1_pt_connectivity_score") |>
  save_fact()
