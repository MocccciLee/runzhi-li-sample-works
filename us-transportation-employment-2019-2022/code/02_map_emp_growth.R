# Clean workspace (optional)
rm(list = ls())

# Packages
library(here)      # project-root relative paths
here::i_am("code/02_map_emp_growth.R")
print(here())                         
library(sf)        # shapefiles
library(ggplot2)   # plotting
library(cowplot)   # layout
library(scales)    # rescale()

# -------------------------
# Load GIS base (counties)
# -------------------------
shp_path <- here("data", "raw", "cb_2018_us_county_5m", "cb_2018_us_county_5m.shp")
county_sf <- st_read(shp_path, quiet = TRUE)

# Tidy county fields and crop to CONUS bbox
colnames(county_sf) <- tolower(colnames(county_sf))
county_sf <- county_sf[, c("statefp", "countyfp", "geometry")]
colnames(county_sf) <- c("state", "county", "geometry")
county_sf <- county_sf[county_sf$state %in% sprintf("%02d", 1:56), ]

us_bbox <- st_bbox(
  c(xmin = -125, ymin = 24.396308, xmax = -66.93457, ymax = 49.384358),
  crs = st_crs(county_sf)
)
county_sf <- st_crop(county_sf, st_as_sfc(us_bbox))

# Ensure zero-padded FIPS in the base layer
county_sf$state  <- sprintf("%02d", as.numeric(county_sf$state))
county_sf$county <- sprintf("%03d", as.numeric(county_sf$county))

# ------------------------------------------
# Helpers: employment map & growth-rate map
# ------------------------------------------
# 1) Choropleth of employment (for a single year)
plot_employment <- function(data_path, plot_title) {
  emp_data <- read.csv(data_path, stringsAsFactors = FALSE)
  colnames(emp_data) <- tolower(colnames(emp_data))
  emp_data <- emp_data[, c("statea", "countya", "emp")]
  colnames(emp_data) <- c("state", "county", "emp")
  emp_data$emp <- as.numeric(emp_data$emp)
  
  # zero-pad FIPS in the table
  emp_data$state  <- sprintf("%02d", as.numeric(emp_data$state))
  emp_data$county <- sprintf("%03d", as.numeric(emp_data$county))
  
  merged <- merge(county_sf, emp_data, by = c("state", "county"), all.x = TRUE)
  
  # equal-frequency bins (6 classes) for a clean legend
  bin_limits <- quantile(merged$emp, probs = seq(0, 1, length.out = 7), na.rm = TRUE)
  bin_labels <- paste0(round(bin_limits[-7]), "–", round(bin_limits[-1]))
  merged$emp_bins <- cut(merged$emp, breaks = bin_limits, labels = bin_labels, include.lowest = TRUE)
  
  ggplot() +
    geom_sf(data = merged, aes(fill = emp_bins), color = NA) +
    scale_fill_brewer(palette = "YlOrRd", name = "Employment") +
    theme_void() +
    labs(
      title = plot_title,
      subtitle = "NAICS 48: Transportation",
      caption = "Data: U.S. Census Bureau"
    )
}

# 2) Choropleth of growth rate (2019→2022)
plot_growth_rate <- function(data_path, plot_title) {
  g <- read.csv(data_path, stringsAsFactors = FALSE)
  colnames(g) <- tolower(colnames(g))
  g <- g[, c("statea", "countya", "growth_rate")]
  colnames(g) <- c("state", "county", "growth_rate")
  g$growth_rate <- as.numeric(g$growth_rate)
  
  g$state  <- sprintf("%02d", as.numeric(g$state))
  g$county <- sprintf("%03d", as.numeric(g$county))
  
  merged <- merge(county_sf, g, by = c("state", "county"), all.x = TRUE)
  
  # drop extreme outliers likely from divide-by-zero
  merged$growth_rate <- ifelse(merged$growth_rate > 1000 | merged$growth_rate < -1000,
                               NA, merged$growth_rate)
  
  ggplot() +
    geom_sf(data = merged, aes(fill = growth_rate), color = NA) +
    scale_fill_gradientn(
      colors = c("#6baed6", "#ffffff", "#f46d43"),
      values = rescale(c(-50, 0, 100)),
      limits = c(-50, 100),
      na.value = "grey85",
      name = "Growth Rate (%)"
    ) +
    theme_void() +
    labs(
      title = plot_title,
      subtitle = "NAICS 48: Transportation",
      caption = "Data: U.S. Census Bureau"
    )
}

# --------------------------------
# Build the three panels (A–C)
# --------------------------------
emp2019 <- plot_employment(
  data_path = here("data", "raw", "data2019.csv"),
  plot_title = "Number of Employees in the Transportation Industry (2019)"
)

emp2022 <- plot_employment(
  data_path = here("data", "raw", "data2022.csv"),
  plot_title = "Number of Employees in the Transportation Industry (2022)"
)

growth <- plot_growth_rate(
  data_path = here("data", "processed", "employment_growth_rate.csv"),
  plot_title = "Employment Growth Rate in the Transportation Industry (2019–2022)"
)

# --------------------------------
# Layout: left (A,B) vs right (C)
# --------------------------------
left_plots <- plot_grid(
  emp2019, emp2022,
  labels = c("A. EMP 2019", "B. EMP 2022"),
  ncol = 1, align = "v",
  rel_heights = c(1, 1),
  label_x = -0.05, label_y = 0.88
) + theme(plot.margin = margin(r = 10, l = 5, unit = "mm"))

right_plot <- plot_grid(
  growth,
  labels = "C. GROWTH RATE",
  label_x = -0.07, label_y = 0.75
) + theme(plot.margin = margin(r = 5, l = 10, unit = "mm"))

combined <- plot_grid(
  left_plots, right_plot,
  rel_widths = c(1.3, 1.7),
  ncol = 2
)

final_plot <- ggdraw(combined) +
  theme(plot.margin = margin(r = 20, l = 20, unit = "mm"))

# -------------------------
# Save to outputs/
# -------------------------
ggsave(
  filename = here("outputs", "Results_Emp&Growth.pdf"),
  plot = final_plot,
  width = 26,   # inches
  height = 16
)