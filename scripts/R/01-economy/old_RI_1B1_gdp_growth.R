# Load packages and source scripts
pacman::p_load(tidyverse, glue, janitor, here, readxl)
source(here::here("scripts", "R", "_common.R"))

# Read in data
RI_1B1_cvm_raw_tbl <- read_excel(
  here::here(
    "data",
    "raw",
    "regionalgrossdomesticproductgdplocalauthorities.xlsx"
  ),
  sheet = "Table 10",
  skip = 1
) ##|> glimpse()

# Define local authorities
local_authorities <- c(
  "Bristol, City of",
  "Bath and North East Somerset",
  "South Gloucestershire",
  "North Somerset"
)

# Clean and filter data
# Create WoE data
weca_cvm_gva_data <- RI_1B1_cvm_raw_tbl |>
  clean_names() |>
  filter(la_name %in% local_authorities) |>
  summarise(across(x2012:x2023, sum)) ##|>
##glimpse()

# Pivot and clean year column
weca_cvm_gva_data_clean <- weca_cvm_gva_data |>
  pivot_longer(x2012:x2023, names_to = "year", values_to = "gdp") |>
  mutate(year = str_remove(year, "x") |> as.integer()) ##|>
##glimpse()

# Create base year variable
base <- weca_cvm_gva_data_clean |>
  filter(year == 2013) |>
  pull(gdp)

# Create index and growth columns
weca_gva_index <- weca_cvm_gva_data_clean |>
  mutate(index = gdp / base * 100) |>
  mutate(growth = (gdp / lag(gdp, 1) - 1) * 100 |> round(1)) |>
  filter(year >= 2013) ##|>
##glimpse()

# Add period_start and period_end as Date objects
weca_gva_index <- weca_gva_index |>
  mutate(
    period_start = make_date(year, 1, 1),
    period_end = make_date(year, 12, 31)
  ) ## |>
##glimpse()

#create upper and lower limits
#function applies the approach and ceiling rounds x up
round_to_interval <- function(x, interval = 10) {
  rounded <- ceiling(x / interval) * interval
  return(rounded)
}

#min and max values from data
min_value <- min(weca_gva_index$index, na.rm = FALSE)
max_value <- max(weca_gva_index$index, na.rm = FALSE)

#lower limit is where floor rounds down the min_value
#upper limit takes the rounded up upper_limit
lower_limit <- floor(min_value / 10) * 10
upper_limit <- round_to_interval(max_value, interval = 10)


# Generate the plot
RI_1B1_plot <- ggplot(weca_gva_index, aes(x = period_start, y = index)) +
  geom_line(linewidth = 1, color = get_weca_color("west_green")) +
  geom_point(size = 2, color = get_weca_color("west_green")) +
  labs(
    title = "GDP growth since 2013",
    subtitle = "Real GDP (excluding inflation) for the West of England",
    x = "Year",
    y = "GDP\ngrowth\n(%)",
    caption = "Source: Office for National Statistics, subnational GDP"
  ) +
  scale_x_date(
    date_breaks = "1 year", # Corrected to singular "year"
    date_labels = "%Y"
  ) +
  scale_y_continuous(limits = c(lower_limit, upper_limit)) +
  theme_weca() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5) # Rotate y-axis title to horizontal
  )

# Display the plot
RI_1B1_plot

# Select columns for the table
RI_1B1_gdp_growth_tbl <- weca_gva_index |>
  select(period_start, period_end, value = growth) ##|>
##glimpse()

# Save fact file
RI_1B1_gdp_growth_tbl |>
  build_fact(
    indicator_id = "RI_1B1_gdp_growth"
  ) |>
  save_fact()

##View(RI_1B1_gdp_growth_tbl)
