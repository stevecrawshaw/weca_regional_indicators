# pacman loads common (i.e. across the project) packages we are using
# source(here::here) puts the scripts we are using into the correct location
library(tidyverse)
library(glue)
library(janitor)
library(here)
library(readxl)
library(scales)
source(here::here("scripts", "R", "_common.R"))

# read in data
RI_1B2_raw_pub_prod_tbl <- read_excel(
  here::here("data", "raw", "labourproductivitylad1.xls"),
  sheet = "B3",
  skip = 4
)

# define our LAs as a variable
weca_la_codes <- c(
  "Bristol, City of",
  "Bath and North East Somerset",
  "South Gloucestershire",
  "North Somerset"
)

# creates variable weca_data
# clean_names makes everything lower-case snake string;
# filter separates our UAs from all others in la_name;
weca_pub_prod_data <- RI_1B2_raw_pub_prod_tbl |>
  clean_names() |>
  filter(lad_name %in% weca_la_codes) ##|>
##glimpse()

# creates variable weca_pub_prod_data_clean;
# selects just relevant UAs and years;
# puts data in long format;
# cleans labels and adds date label
weca_pub_prod_data_clean <- weca_pub_prod_data |>
  select(lad_name, pounds_2013:pounds_2023) |>
  pivot_longer(
    pounds_2013:pounds_2023,
    names_to = "year",
    values_to = "gva_per_job"
  ) |>
  mutate(
    year = str_remove(year, "pounds_"),
    Date = glue("{year}-01-01") |>
      as.Date()
  ) ##|>
##glimpse()

# read in data
RI_1B2_raw_pub_jobs_tbl <- read_excel(
  here::here("data", "raw", "labourproductivitylad1.xls"),
  sheet = "Productivity Jobs",
  skip = 4
) ##|>
##glimpse()

# creates variable weca_data_jobs_data
# clean_names makes everything lower-case snake string;
# filter separates our UAs from all others in la_name;
weca_pub_jobs_data <- RI_1B2_raw_pub_jobs_tbl |>
  clean_names() |>
  filter(lad_name %in% weca_la_codes) ##|>
####glimpse()

# creates variable weca_pub_jobs_data_clean;
# selects just relevant UAs and years;
# puts data in long format;
# cleans labels and adds date label
weca_pub_jobs_data_clean <- weca_pub_jobs_data |>
  select(lad_name, jobs_2013:jobs_2023) |>
  pivot_longer(
    jobs_2013:jobs_2023,
    names_to = "year",
    values_to = "prod_jobs"
  ) |>
  mutate(
    year = str_remove(year, "jobs_"),
    Date = glue("{year}-01-01") |>
      as.Date()
  ) ##|>
####glimpse()

# creates variable weca_prod_data;
# joins jobs and gva data frames with inner_join;
# multipluies prod_jobs with gva_per_job to get ua gva;
# aggregates ua gva to get weca gva
# groups by date in prep for aggregation of ua data for each year
# aggregates year, jobs and creates weca_prod
# creates start, end and value (weca_prod)
RI_1B2_gva_per_job_tbl <- weca_pub_jobs_data_clean |>
  inner_join(
    weca_pub_prod_data_clean,
    by = join_by("Date" == "Date", "lad_name" == "lad_name")
  ) |>
  mutate(gva = prod_jobs * gva_per_job) |>
  group_by(Date) |>
  summarise(
    weca_gva = sum(gva),
    weca_jobs = sum(prod_jobs),
    weca_prod = weca_gva / weca_jobs
  ) |>
  mutate(period_start = Date, period_end = Date + years(1) - days(1)) |>
  select(period_start, period_end, value = weca_prod) ##|>
####glimpse()

#create upper and lower limits
#function applies the approach and ceiling rounds x up
round_to_interval <- function(x, interval = 5000) {
  rounded <- ceiling(x / interval) * interval
  return(rounded)
}

#min and max values from data
min_value <- min(RI_1B2_gva_per_job_tbl$value, na.rm = FALSE)
max_value <- max(RI_1B2_gva_per_job_tbl$value, na.rm = FALSE)

#lower limit is where floor rounds down the min_value
#upper limit takes the rounded up upper limit
lower_limit <- floor(min_value / 5000) * 5000
upper_limit <- round_to_interval(max_value, interval = 5000)


# plots data
RI_1B2_plot <- ggplot(
  RI_1B2_gva_per_job_tbl,
  aes(x = period_start, y = value)
) +
  geom_line(color = get_weca_color("west_green")) +
  geom_point(color = get_weca_color("west_green")) +
  labs(
    title = "Annual GVA per job, 2013-2023",
    subtitle = "Current price GVA (including inflation) per job for the West of England",
    x = "Year",
    y = "GVA\nper job",
    caption = "Source: Office for National Statistics, subnational productivity"
  ) +
  scale_y_continuous(
    limits = c(lower_limit, upper_limit),
    labels = scales::label_currency(prefix = "£")
  ) +
  #scale_x_continuous(breaks = unique(weca_prod_data$period_start)) +
  theme_weca() +
  theme(axis.title.y = element_text(angle = 0, vjust = 0.5))


# RI_1B2_plot

# Save fact file
RI_1B2_gva_per_job_tbl |>
  build_fact(
    indicator_id = "RI_1B2_gva"
  ) |>
  save_fact()

##View(RI_1B2_gva_per_job_tbl)
