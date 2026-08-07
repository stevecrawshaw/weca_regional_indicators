# load libraries and functions ------------------------------------------------
pacman::p_load(httr2, jsonlite, tidyverse, glue, janitor, here)
source(here::here("scripts", "R", "_common.R"))

# Get the data from the open data portal using httr2 and the ODS API ----------
RI_5_base_url <- "https://opendata.westofengland-ca.gov.uk/api/explore/v2.1/catalog/datasets"
RI_5_endpoint <- "records"
RI_5_indicator_id <- "RI_5_ghg_emissions"
# parameters
RI_5_dataset_id <- "ca_la_ghg_emissions_sub_sector_ods_vw"
RI_5_kpi_sectors <- c(
  "Transport",
  "Commercial",
  "Industry",
  "Public Sector",
  "Domestic"
)
cauthnm <- "West of England"
period_years <- 10

# get the last year in the dataset
resp_max_year <- request(RI_5_base_url) |>
  req_url_path_append(RI_5_dataset_id, RI_5_endpoint) |>
  req_url_query(
    "select" = "max(calendar_year) AS YEAR",
    "limit" = 1
  ) |>
  req_perform()

RI_5_max_date <- resp_max_year |>
  resp_body_json() |>
  pluck("results", 1, "YEAR") |>
  strptime("%Y-%m-%dT%H:%M:%S")

RI_5_start_date <- (RI_5_max_date - years(period_years - 1)) |>
  strftime("%Y-%m-%dT%H:%M:%S")

# make the API call for KPI sector chart
resp <- request(RI_5_base_url) |>
  req_url_path_append(RI_5_dataset_id, RI_5_endpoint) |>
  req_url_query(
    "select" = "sum(territorial_emissions_kt_co2e) AS territorial_emissions_kt_co2e",
    "where" = glue::glue(
      "calendar_year IN [date'{RI_5_start_date}'..date'{RI_5_max_date}'] AND cauthnm='{cauthnm}'"
    ),
    "group_by" = "la_ghg_sector AS sector,calendar_year",
    "limit" = 100
  ) |>
  req_perform()

# process the response object to get the tbl
RI_5_sector_emissions_weca_tbl <- resp |>
  resp_body_json() |>
  pluck("results") |>
  bind_rows() |>
  mutate(
    year = calendar_year |> strptime("%Y") |> year(),
    calendar_year = NULL
  )

RI_5_kpi_sector_weca_tbl <- RI_5_sector_emissions_weca_tbl |>
  filter(sector %in% RI_5_kpi_sectors)

sector_names <- RI_5_kpi_sector_weca_tbl |>
  distinct(sector) |>
  pull(sector)

sector_count <- length(sector_names)

fill_colors <-
  weca_colors[1:sector_count] |>
  set_names(sector_names)

RI_5_plot <- RI_5_kpi_sector_weca_tbl |>
  group_by(sector) |>
  ggplot() +
  geom_col(aes(
    x = year,
    y = territorial_emissions_kt_co2e,
    fill = sector
  )) +
  labs(
    title = "Greenhouse Gas Emission Trends by Sector",
    subtitle = "West of England",
    x = "Year",
    y = "Kt CO2e",
    fill = "Sector",
    caption = "Source DESNZ"
  ) +
  scale_fill_manual(values = fill_colors) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))

# RI_5_plot

# Now the chart for sector emission from current year

RI_5_sector_current_year_tbl <- RI_5_sector_emissions_weca_tbl |>
  filter(year == RI_5_max_date |> year())

total_emissions_current_year <- RI_5_sector_current_year_tbl |>
  summarise(
    total_emissions = sum(territorial_emissions_kt_co2e, na.rm = TRUE)
  ) |>
  pull(total_emissions)

RI_5_sector_current_year_plot_tbl <-
  RI_5_sector_current_year_tbl |>
  mutate(
    percent_total_emissions = round(
      territorial_emissions_kt_co2e / total_emissions_current_year * 100
    ),
    sector = fct_reorder(sector, percent_total_emissions)
  )

RI_5_sector_current_year_plot <-
  RI_5_sector_current_year_plot_tbl |>
  ggplot() +
  geom_col(
    aes(
      x = sector,
      y = territorial_emissions_kt_co2e
    ),
    fill = get_weca_color("west_green")
  ) +
  labs(
    title = "Latest Greenhouse Gas Emissions by Sector",
    subtitle = glue::glue(
      "West of England - {RI_5_max_date |> year()}"
    ),
    x = "Sector",
    y = "Total emissions (Kt CO2e)",
    caption = "Source DESNZ"
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  geom_text(
    aes(
      x = sector,
      y = territorial_emissions_kt_co2e,
      label = glue::glue("{percent_total_emissions}%")
    ),
    hjust = -0.3
  ) +
  coord_flip() +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))


RI_5_kpi_base_data_tbl <- RI_5_kpi_sector_weca_tbl |>
  group_by(year) |>
  summarise(
    total_emissions_kpi_sectors = sum(
      territorial_emissions_kt_co2e,
      na.rm = TRUE
    )
  ) |>
  arrange(year)

RI_5_fact_tbl <- RI_5_kpi_base_data_tbl |>
  mutate(
    period_start = dmy(glue::glue("01-01-{year}")),
    period_end = dmy(glue::glue("31-12-{year}")),
    value = total_emissions_kpi_sectors,
    year = NULL,
    total_emissions_kpi_sectors = NULL
  ) |>
  build_fact(indicator_id = "RI_5_ghg_emissions")

RI_5_fact_tbl |> save_fact()
