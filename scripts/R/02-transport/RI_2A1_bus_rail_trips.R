library("tidyverse")
library("here")
library("janitor")
library("readxl")
library("glue")

source(here::here("scripts", "R", "_common.R"))

RI_2A1_bus_rail_trips <- read_excel(
  path = here("data", "raw", "Public Transport Patronage.xlsx"),
  sheet = "Data"
) |>
  clean_names() |>
  mutate(
    period_start = as.Date(glue("{str_sub(date,1,4)}-04-01")),
    period_end = as.Date(glue("20{str_sub(date,6,7)}-03-31"))
  ) |>
  select(
    period_start,
    period_end,
    bus_per_head,
    rail_per_head,
    public_transport_per_head,
    bus_per_head_england,
    rail_per_head_england,
    public_transport_england
  ) |>
  # you have some NA values so need to add a filter condition so you only ingest valid data
  filter(!is.na(bus_per_head))


RI_2A1_bus_rail_plot_tbl <- RI_2A1_bus_rail_trips |>
  select(
    period_start,
    period_end,
    bus_per_head,
    rail_per_head,
    public_transport_per_head,
    bus_per_head_england,
    rail_per_head_england,
    public_transport_england
  ) |>
  pivot_longer(
    cols = c(bus_per_head, rail_per_head, public_transport_per_head),
    #, bus_per_head_england, rail_per_head_england, public_transport_england
    names_to = "mode_type",
    values_to = "value"
  ) |>
  mutate(
    mode_type = case_when(
      mode_type == "bus_per_head" ~ "Bus",
      mode_type == "rail_per_head" ~ "Rail",
      mode_type == "public_transport_per_head" ~ "Public Transport"
    )
  )


bus_rail_colours <- weca_colors[1:3]

bus_rail_colours_named <-
  bus_rail_colours |>
  set_names("Bus", "Rail", "Public Transport")


RI_2A1_plot <-
  RI_2A1_bus_rail_plot_tbl |>
  ggplot(aes(
    x = period_end,
    y = value,
    fill = fct_relevel(
      mode_type,
      c("Public Transport", "Bus", "Rail")
    )
  )) +
  geom_col(position = "dodge") +
  # note how to split text over lines with \n
  labs(
    title = "Public transport patronage",
    subtitle = "Department for Transport and Office of Rail Regulator estimates",
    x = "Financial year end",
    y = "Trips per\nperson per\nyear",
    fill = "Mode"
  ) +

  scale_fill_manual(values = bus_rail_colours_named) +
  theme_weca() +
  # note how to make horizontal y axis title vertically
  # justified at halfway on axis
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

RI_2A1_plot

# This is the bit that writes the fact table which is used to make the nice tables in the quarto report
RI_2A1_bus_rail_plot_tbl |>
  filter(mode_type == "Public Transport") |>
  select(period_start, period_end, value) |>
  build_fact("RI_2A1_bus_rail_trips") |>
  save_fact()
