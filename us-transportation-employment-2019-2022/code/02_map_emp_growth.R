# 清空环境
remove(list = ls())

# 加载必要包
library(sf)
library(ggplot2)
library(cowplot)
library(scales)
# 设置工作目录
setwd("/Users/lirunzhi/Desktop/Mapping project")

# 加载 Shapefile 文件
county_sf <- st_read("/Users/lirunzhi/Desktop/Mapping project/cb_2018_us_county_5m/cb_2018_us_county_5m.shp")

# 准备 GIS 数据
colnames(county_sf) <- tolower(colnames(county_sf))
county_sf <- county_sf[, c("statefp", "countyfp", "geometry")]
colnames(county_sf) <- c("state", "county", "geometry")
county_sf <- county_sf[county_sf$state %in% sprintf("%02d", 1:56), ]
us_bbox <- st_bbox(c(xmin = -125, ymin = 24.396308, xmax = -66.93457, ymax = 49.384358), crs = st_crs(county_sf))
us_bbox <- st_as_sfc(us_bbox)
county_sf <- st_crop(county_sf, us_bbox)

# 定义绘图函数 --------------------------------------------------------------
# 1. 绘制就业人数图（2019/2022）
plot_employment <- function(data_path, plot_title) {
  emp_data <- read.csv(file = data_path)
  colnames(emp_data) <- tolower(colnames(emp_data))
  emp_data <- emp_data[, c("statea", "countya", "emp")]
  colnames(emp_data) <- c("state", "county", "pop")
  emp_data$pop <- as.numeric(emp_data$pop)
  
  county_sf$state <- sprintf("%02d", as.numeric(county_sf$state))
  county_sf$county <- sprintf("%03d", as.numeric(county_sf$county))
  emp_data$state <- sprintf("%02d", as.numeric(emp_data$state))
  emp_data$county <- sprintf("%03d", as.numeric(emp_data$county))
  
  merged_data <- merge(county_sf, emp_data, by = c("state", "county"), all.x = TRUE)
  
  bin_limits <- quantile(merged_data$pop, probs = seq(0, 1, length.out = 7), na.rm = TRUE)
  bin_labels <- paste0(round(bin_limits[-7]), "-", round(bin_limits[-1]))
  merged_data$population_bins <- cut(
    merged_data$pop,
    breaks = bin_limits,
    labels = bin_labels,
    include.lowest = TRUE
  )
  
  ggplot() +
    geom_sf(data = merged_data, aes(fill = population_bins), color = NA) +
    scale_fill_brewer(palette = "YlOrRd", name = "Employment") +
    theme_void() +
    labs(
      title = plot_title,
      subtitle = "NAICS 48: Transportation",
      caption = "Data: United States Census Bureau"
    )
}

# 2. 绘制增长率图
plot_growth_rate <- function(data_path, plot_title) {
  growth_data <- read.csv(data_path)
  colnames(growth_data) <- tolower(colnames(growth_data))
  growth_data <- growth_data[, c("statea", "countya","growth_rate")]
  colnames(growth_data) <- c("state", "county", "growth_rate")
  growth_data$growth_rate <- as.numeric(growth_data$growth_rate)
  
  county_sf$state <- sprintf("%02d", as.numeric(county_sf$state))
  county_sf$county <- sprintf("%03d", as.numeric(county_sf$county))
  growth_data$state <- sprintf("%02d", as.numeric(growth_data$state))
  growth_data$county <- sprintf("%03d", as.numeric(growth_data$county))
  
  merged_data <- merge(county_sf, growth_data, by = c("state", "county"), all.x = TRUE)
  merged_data$growth_rate <- ifelse(merged_data$growth_rate > 1000 | merged_data$growth_rate < -1000, NA, merged_data$growth_rate)
  
  ggplot() +
    geom_sf(data = merged_data, aes(fill = growth_rate), color = NA) +
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
      caption = "Data: United States Census Bureau"
    )
}

# 创建单独图表 -------------------------------------------------------------
plot_emp_2019 <- plot_employment(
  data_path = "data2019.csv",
  plot_title = "Number of Employees in the Transportation Industry (2019)"
)

plot_emp_2022 <- plot_employment(
  data_path = "data2022.csv",
  plot_title = "Number of Employees in the Transportation Industry (2022)"
)

plot_growth <- plot_growth_rate(
  data_path = "employment_growth_rate.csv",
  plot_title = "Employment Growth Rate in the Transportation Industry (2019-2022)"
)

# 将三个图合成一页 ----------------------------------------------------------
# 调整左右两部分布局比例
left_plots <- plot_grid(
  plot_emp_2019, plot_emp_2022,
  labels = c("A. EMP 2019", "B. EMP 2022"),
  ncol = 1,
  align = "v",
  rel_heights = c(1, 1), # 左侧上下两图等高
  label_x = -0.05,        # 左移标签
  label_y = 0.88          # 下移标签
)

# 右边增长率图单独处理
right_plot <- plot_grid(
  plot_growth,
  labels = c("C. GROWTH RATE"),
  label_x = -0.07,
  label_y = 0.75
)

left_plots <- left_plots + 
  theme(plot.margin = margin(r = 10, l = 5, unit = "mm"))  # 左图右边轻微增加边距
right_plot <- right_plot + 
  theme(plot.margin = margin(r = 5, l = 10, unit = "mm"))  # 右图左边轻微增加边距

# 组合左右布局，调整左右比例
combined_plot <- plot_grid(
  left_plots, right_plot,
  rel_widths = c(1.3, 1.7),  # 调整左右子图宽度比例
  ncol = 2                   # 两列布局
)

# 增加整个布局的边距
final_plot <- ggdraw(combined_plot) +
  theme(plot.margin = margin(r = 20,l = 20, unit = "mm"))  # 设置边距

# 保存优化后的 PDF
ggsave(
  filename = "Econ129_Emp&Growth.pdf",
  plot = final_plot,
  width = 26,  # 调整画布宽度
  height = 16  # 调整画布高度
)