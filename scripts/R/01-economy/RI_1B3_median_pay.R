# pacman loads common (i.e. across the project) packages we are using
# source(here::here) puts the scripts we are using into the correct location
library(tidyverse)
library(glue)
library(janitor)
library(here)
library(readxl)
library(scales)
source(here::here("scripts", "R", "_common.R"))

# read in median wage data
RI_1B3_raw <- read_excel(
  here::here("data", "raw", "rtinsajun2026.xlsx"),
  sheet = "20. Median pay (LA)",
  skip = 7
)


# define our LAs as a variable
weca_la_codes <- c(
  "Bristol, City of",
  "Bath and North East Somerset",
  "South Gloucestershire",
  "North Somerset"
)

#pivot the table and filter to the relevant LAs
#clean and make the date month and year (my)
la_med_wage_data <- RI_1B3_raw |>
  pivot_longer(cols = -Date, names_to = "la", values_to = "median_wage") |>
  filter(la %in% weca_la_codes) |>
  clean_names() |>
  mutate(date = my(date))


# read in employee data for weights
RI_1B3_raw_employees <- read_excel(
  here::here("data", "raw", "rtinsajun2026.xlsx"),
  sheet = "19. Employees (LA)",
  skip = 7
)

#pivot the table and filter to the relevant LAs
#clean and make the date month and year (my)
la_employee_data <- RI_1B3_raw_employees |>
  pivot_longer(cols = -Date, names_to = "la", values_to = "employees") |>
  filter(la %in% weca_la_codes) |>
  clean_names() |>
  mutate(date = my(date))


# calculate the weights
# method: LA employee total / region employee total will provide LA weight
# LA weight * LA median wage provides LA weighted median wage data
# sum LA weighted median wage data from each LA to get weighted median wage for the region
la_employee_data_weighted <- la_employee_data |>
  group_by(date) |>
  mutate(weight = employees / sum(employees)) |>
  ungroup()

# combine the data using date and LA then calculate weighted data
combined_data <- la_employee_data_weighted |>
  left_join(la_med_wage_data, by = c("date", "la")) |>
  mutate(weighted_wage = weight * median_wage)

# sum data for weca median wage
la_estimate <- combined_data |>
  group_by(date) |>
  summarise(estimated_wage = sum(weighted_wage)) |>
  ungroup()

# set dates for table
max_date <- max(la_estimate$date)

start_date <- max_date - years(10)

# Filter to 10 years
la_estimate_10_years <- la_estimate |>
  filter(date > start_date)

# Create table
RI_1B3_median_wage_tbl <- la_estimate_10_years |>
  mutate(
    period_start = date,
    period_end = rollforward(date),
    value = estimated_wage
  ) |>
  select(period_start, period_end, value)

# save_fact
RI_1B3_median_wage_tbl |>
  build_fact(
    indicator_id = "RI_1B3_median_pay"
  ) |>
  save_fact()

#create upper and lower limits
#function applies the approach and ceiling rounds x up
round_to_interval <- function(x, interval = 250) {
  rounded <- ceiling(x / interval) * interval
  return(rounded)
}

#min and max values from data
min_value <- min(RI_1B3_median_wage_tbl$value, na.rm = FALSE)
max_value <- max(RI_1B3_median_wage_tbl$value, na.rm = FALSE)

#lower limit is where floor rounds down the min_value
#upper limit takes the rounded up upper limit
lower_limit <- floor(min_value / 250) * 250
upper_limit <- round_to_interval(max_value, interval = 250)


# Generate the plot
RI_1B3_plot <- ggplot(la_estimate_10_years, aes(x = date, y = estimated_wage)) +
  geom_line(color = get_weca_color("west_green")) +
  # geom_point(color = get_weca_color("west_green")) +
  labs(
    title = "Median monthly wage since 2016",
    subtitle = "Changes in the median wage for the region",
    x = "Year",
    y = "Median\nwage",
    caption = "Source: Office for National Statistics, HMRC PAYE data and own calculations"
  ) +
  scale_x_date(
    date_breaks = "1 year", # Corrected to singular "year"
    date_labels = "%Y"
  ) +
  scale_y_continuous(
    limits = c(lower_limit, upper_limit),
    labels = scales::label_currency(prefix = "£")
  ) +
  theme_weca() +
  theme(
    axis.title.y = element_text(angle = 0, vjust = 0.5) # Rotate y-axis title to horizontal
  )

# Display the plot
# RI_1B3_plot
