# Load packages and source scripts
pacman::p_load(tidyverse, glue, janitor, here, readxl)
source(here::here("scripts", "R", "_common.R"))

# Read in cvm data
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
  mutate(year = str_remove(year, "x") |> as.integer()) ## |>
## glimpse()

# Calculate growth rates for 2012 to 2023
weca_cvm_gva_growth <- weca_cvm_gva_data_clean |>
  arrange(year) |>
  mutate(
    year = as.numeric(sub("x", "", year)),
    growth_rate = (gdp - lag(gdp)) / lag(gdp) * 100 # Percentage change formula
  ) |>
  filter(year >= 2014)

## glimpse(weca_cvm_gva_growth)

# Read in cp data
RI_1B1_cp_raw <- read_excel(
  here::here(
    "data",
    "raw",
    "regionalgrossdomesticproductgdplocalauthorities.xlsx"
  ),
  sheet = "Table 5",
  skip = 1
) ## |> glimpse()


# Clean and filter data
weca_cp_gva_data <- RI_1B1_cp_raw |>
  clean_names() |>
  filter(la_name %in% local_authorities) ## |>
## glimpse()

# Aggregate CP data for 2023
base_price_2023 <- weca_cp_gva_data |>
  summarise(cp_2023 = sum(x2023, na.rm = TRUE)) |>
  pull(cp_2023) ## |>
## glimpse()

# create CVM series in 2023 prices
weca_cvm_series <- tibble(
  year = 2014:2023,
  growth_rate = weca_cvm_gva_growth$growth_rate
) |>
  mutate(
    factor = cumprod(1 + growth_rate / 100),
    cvm_value = factor / factor[year == 2023] * base_price_2023
  )

## glimpse(weca_cvm_series)

# Add period_start and period_end as Date objects
weca_cvm_series <- weca_cvm_series |>
  mutate(
    period_start = make_date(year, 1, 1),
    period_end = make_date(year, 12, 31)
  ) ## |> glimpse()

#create upper and lower limits
#function applies the approach and ceiling rounds x up
round_to_interval <- function(x, interval = 10) {
  rounded <- ceiling(x / interval) * interval
  return(rounded)
}

#min and max values from data
min_value <- min(weca_cvm_series$cvm_value, na.rm = FALSE)
max_value <- max(weca_cvm_series$cvm_value, na.rm = FALSE)

#lower limit is where floor rounds down the min_value
#upper limit takes the rounded up upper_limit
lower_limit <- floor(min_value / 10) * 10
upper_limit <- round_to_interval(max_value, interval = 10)


# Generate the plot
RI_1B1_plot <- ggplot(weca_cvm_series, aes(x = period_start, y = cvm_value)) +
  geom_line(color = get_weca_color("west_green")) +
  geom_point(color = get_weca_color("west_green")) +
  labs(
    title = "GDP growth in 2023 prices",
    subtitle = "Real GDP (excluding inflation) for the West of England",
    x = "Year",
    y = "GDP\n(£m)",
    caption = "Source: Office for National Statistics, subnational GDP"
  ) +
  scale_x_date(
    date_breaks = "1 year", # Corrected to singular "year"
    date_labels = "%Y"
  ) +
  scale_y_continuous(
    limits = c(lower_limit, upper_limit),
    labels = scales::label_dollar(prefix = "£", big.mark = ",")
  ) +

  theme_weca() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5) # Rotate y-axis title to horizontal
  )

# Display the plot
# RI_1B1_plot

# Select columns for the table
RI_1B1_gdp_growth_tbl <- weca_cvm_series |>
  select(period_start, period_end, value = cvm_value) ## |>
## glimpse()

# Save fact file
RI_1B1_gdp_growth_tbl |>
  build_fact(
    indicator_id = "RI_1B1_gdp_growth"
  ) |>
  save_fact()

##View(RI_1B1_gdp_growth_tbl)
