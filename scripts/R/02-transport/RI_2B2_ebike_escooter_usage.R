library("tidyverse")
library("here")
library("janitor")
library("readxl")
library("glue")

source(here::here("scripts", "R", "_common.R"))

RI_2B2_ebike_escooter_usage <- read_excel(
  path = here("data", "raw", "MicromobilityTrips.xlsx"),
  sheet = "Annual"
) |>

  clean_names() |>

  mutate(
    period_start = as.Date(glue("{year}-01-01")),
    period_end = as.Date(glue("{year}-12-31"))
  ) |>
  select(period_start, period_end, escooter, ebike, ehire)

RI_2B2_ebike_escooter_usage_plot_tbl <- RI_2B2_ebike_escooter_usage |>
  select(period_start, period_end, escooter, ebike, ehire) |>

  pivot_longer(
    cols = c(escooter, ebike, ehire),
    names_to = "mode_type",
    values_to = "value"
  ) |>
  mutate(
    mode_type = case_when(
      mode_type == "ebike" ~ "e-bike",
      mode_type == "escooter" ~ "e-scooter",
      mode_type == "ehire" ~ "e-hire"
    )
  )

ehire_colours <- weca_colors[1:3]

ehire_colours_named <-
  ehire_colours |>
  set_names("e-scooter", "e-bike", "e-hire")

RI_2B2_plot <-
  RI_2B2_ebike_escooter_usage_plot_tbl |>
  ggplot(aes(
    x = period_end,
    y = value,
    fill = fct_relevel(mode_type, c("e-hire", "e-scooter", "e-bike"))
  )) +
  geom_col(position = "dodge") +
  labs(
    title = "WESTscoot and WESTbike patronage",
    caption = "Operated by Voi (Oct 24 - Aug 23), Tier (Sept 23- Aug 24), Dott (Sept 24 - present)",
    x = "Year",
    y = "Trips",
    fill = "Mode"
  ) +

  scale_fill_manual(values = ehire_colours_named) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

# RI_2B2_plot

# This is the bit that writes the fact table which is used to make the nice tables in the quarto report
RI_2B2_ebike_escooter_usage_plot_tbl |>
  filter(mode_type == "e-hire") |>
  select(period_start, period_end, value) |>
  build_fact("RI_2B2_ebike_escooter_usage") |>
  save_fact()
