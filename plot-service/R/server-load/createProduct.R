########################################################################
# server-load/createProduct.R
#
# Create a load/memory/disk usage timeseries chart.
#
# Author: Mazama Science
########################################################################

#' @title Create load/memory/disk usage timeseries chart
#'
#' @description
#'

createProduct <- function(
  dataList = NULL, 
  infoList = NULL, 
  textList = NULL
) {
  
  logger.debug("----- server-load/createProduct() -----")
  
  # ----- Validate parameters --------------------------------------------------
  
  MazamaCoreUtils::stopIfNull(dataList)
  MazamaCoreUtils::stopIfNull(infoList)
  MazamaCoreUtils::stopIfNull(textList)
  
  # ----- Get parameters -------------------------------------------------------
  
  serverid <- infoList$serverid
  ymax <- infoList$ymax
  plotPath <- infoList$plotPath
  width <- infoList$width
  height <- infoList$height
  dpi <- infoList$dpi
  units <- infoList$units
  
  loadData <- dataList$loadData
  memoryData <- dataList$memoryData
  diskData <- dataList$diskData
  
  loadThreshold <- 1.8 # most AWS instances have 2 cores
  memoryUnavailableRatioThreshold <- 0.9
  diskUsageThreshold   <- 0.9
  
  # ----- Create plot ----------------------------------------------------------
  
  # Determine what year(s) should be displayed on the x axis
  startYear <- as.integer(format(loadData[nrow(loadData),1][[1]], "%Y"))
  endYear <- as.integer(format(loadData[1,1][[1]], "%Y"))
  xLabel <- paste0(endYear)
  if (endYear - startYear > 0) {
    xLabel = paste0(startYear, "-", endYear)
  }
  
  # Set load scale limit to 1.0 by default, max if the data exceeds 1, or to 
  # the value given by the user
  if ( ymax < 0.02 ) {
    primary_y_lim = max(1.0, max(loadData$load_15_min) * 1.1)
  } else {
    primary_y_lim = ymax
  }
  
  # Scale the disk usage data so that 100% matches full plot height
  diskData$scaledUsage <- diskData$used * primary_y_lim
  
  # Scale the memory axis so the total memory matches the height of the load axis
  memory_scale_factor = max(memoryData$total, na.rm = TRUE) / primary_y_lim
  
  # Get the data for the last hour
  loadData_lastHour <- tail(loadData, 5)
  memoryData_lastHour <- tail(memoryData, 5) %>% 
    mutate(unavailableRatio = (total - available) / total)
  diskData_lastHour <- tail(diskData, 5)
  
  # Show an eye-catching red plot border if any of the load, memory, or disk 
  # data exceed a dangerous threshold
  border_color <- NULL
  if (max(loadData_lastHour$load_15_min, na.rm = TRUE) >= loadThreshold ||
      max(memoryData_lastHour$unavailableRatio, na.rm = TRUE) >= memoryUnavailableRatioThreshold ||
      max(diskData_lastHour$used, na.rm = TRUE)        >= diskUsageThreshold) {
    border_color <- 'red'
  }
  
  basePlot <- ggplot() +
    geom_area(data = diskData, aes(x = datetime, y = scaledUsage, fill = "Disk usage")) + 
    geom_step(data = memoryData, aes(x = datetime, y = unavailable / memory_scale_factor, linetype = "Unavailable"), size = 1.3, color = "goldenrod1") +
    geom_line(data = memoryData, aes(x = datetime, y = total / memory_scale_factor, linetype = "Total"), size = 1.3, color = "goldenrod1") + 
    geom_step(data = loadData, aes(x = datetime, y = load_15_min, color = "Server load")) +
    scale_colour_manual("", values = c("Server load" = "black", "Disk usage" = rgb(0, 0, 0, 0.1))) +
    scale_linetype_manual("Memory", values = c("Total" = "twodash", "Unavailable" = "solid")) +
    scale_fill_manual("", values = c("Server load" = "black", "Disk usage" = rgb(0, 0, 0, 0.1))) +
    scale_y_continuous(sec.axis = sec_axis(~.*memory_scale_factor/1000, name = "\nMemory Usage (GB)\n")) +
    coord_cartesian(ylim = c(0, primary_y_lim)) +
    theme(legend.position = "right") + 
    labs(
      title = paste0("Server Health: ", serverid, "\n"),
      x = xLabel,
      y = "\n15 Minute Load\n") +
    ggthemes::theme_hc() +               # Using theme_hc() restricts setting the panel background color
    theme(panel.background = element_rect(fill = 'white', color = border_color, size = 4, linetype = 'solid'))
  
  if ( infoList$lookbackdays < 3 ) {
    
    # start <- lubridate::floor_date(range(loadData$datetime)[1], unit="day")
    # end <- lubridate::ceiling_date(range(loadData$datetime)[2], unit="day")
    # minor_breaks <- seq.POSIXt(start, end, by="3 hour")
    
    gg <- basePlot +
      scale_x_datetime(
        date_labels = "%b %d",
        date_breaks = "1 day",
        date_minor_breaks = "3 hours" # TODO:  Why aren't these showing?
      )
    
  } else {
    
    gg <- basePlot +
      scale_x_datetime(
        date_labels = "%b %d",
        date_breaks = "1 day"
      )
    
  }
  
  # ----- Save plot ------------------------------------------------------------
  
  ggsave(
    plotPath,
    plot = gg,
    width = width,
    height = height,
    dpi = dpi,
    units = units
  )
  
  return(invisible())
  
}
