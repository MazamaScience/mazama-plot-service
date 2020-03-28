########################################################################
# uptime/createProduct.R
#
# Create a Uptime / load timeseries chart.
#
# Author: Spencer Pease, Jonathan Callahan
########################################################################

#' @title Create Uptime / load timeseries chart
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
  
  uptimeData <- dataList$uptimeData
  memoryData <- dataList$memoryData
  diskData <- dataList$diskData
  
  uptimeLoadThreshold <- 0.9
  memoryUsedRatioThreshold <- 8.0
  diskUsedThreshold   <- 0.9
  
  # ----- Create plot ----------------------------------------------------------
  
  # Determine what year(s) should be displayed on the x axis
  startYear <- as.integer(format(uptimeData[nrow(uptimeData),1][[1]], "%Y"))
  endYear <- as.integer(format(uptimeData[1,1][[1]], "%Y"))
  xLabel <- paste0(endYear)
  if (endYear - startYear > 0) {
    xLabel = paste0(startYear, "-", endYear)
  }
  
  # Set uptime scale limit to 1.0 by default, max if the data exceeds 1, or to 
  # the value given by the user
  if (ymax < 0.02) {
    primary_y_lim = max(1.0, max(uptimeData$load_15_min) * 1.1)
  } else {
    primary_y_lim = ymax
  }
  
  # Scale the memory axis so the total memory matches the height of the uptime axis
  scale_factor = max(memoryData$total, na.rm=TRUE) / primary_y_lim
  
  # Get the data for the last hour
  uptimeData_lastHour <- tail(uptimeData, 5)
  memoryData_lastHour <- tail(memoryData, 5) %>% 
    mutate(usedRatio = used / free)
  diskData_lastHour <- tail(diskData, 5)
  
  # Show an eye-catching red plot border if any of the uptime, memory, or disk 
  # data exceed a dangerous threshold
  border_color <- NULL
  if (max(uptimeData_lastHour$load_15_min, na.rm = TRUE) >= uptimeLoadThreshold ||
      max(memoryData_lastHour$usedRatio, na.rm = TRUE)   >= memoryUsedRatioThreshold ||
      max(diskData_lastHour$used, na.rm = TRUE)          >= diskUsedThreshold) {
    border_color <- 'red'
  }
  
  basePlot <- ggplot() +
    geom_area(data = diskData, aes(x = datetime, y = used, fill = "Disk usage")) + 
    geom_step(data = uptimeData, aes(x = datetime, y = load_15_min, color = "Server load")) +
    geom_step(data = memoryData, aes(x = datetime, y = used / scale_factor, linetype = "Used"), size = 1.3, color = "goldenrod1") +
    geom_line(data = memoryData, aes(x = datetime, y = total / scale_factor, linetype = "Total"), size = 1.3, color = "goldenrod1") + 
    scale_linetype_manual("Memory", values = c("Total" = "twodash", "Used" = "solid")) +
    scale_colour_manual("Load", values = c("Server load" = "black", "Disk usage" = rgb(0, 0, 0, 0.1))) +
    scale_fill_manual("Load", values = c("Server load" = "black", "Disk usage" = rgb(0, 0, 0, 0.1))) +
    #guides(color = guide_legend(order = 1, label.position = "left"), linetype = guide_legend(order = 2, label.position = "right")) + 
    #guides(color = guide_legend(order = 1), linetype = guide_legend(order = 2)) + 
    #theme(legend.margin = unit(width, "cm")) + 
    scale_y_continuous(sec.axis = sec_axis(~.*scale_factor/1000, name = "\nMemory Usage (GB)\n")) +
    coord_cartesian(ylim = c(0, primary_y_lim)) +
    theme(legend.position="right") + 
    labs(
      title = paste0("Server Health: ", serverid, "\n"),
      x = xLabel,
      y = "\n15 Minute Load\n") +
    ggthemes::theme_hc() +               # Using theme_hc() restricts setting the panel background color
    theme(panel.background = element_rect(fill = 'white', color = border_color, size = 4, linetype = 'solid'))
  
  if ( infoList$lookbackdays < 3 ) {
    
    # start <- lubridate::floor_date(range(uptimeData$datetime)[1], unit="day")
    # end <- lubridate::ceiling_date(range(uptimeData$datetime)[2], unit="day")
    # minor_breaks <- seq.POSIXt(start, end, by="3 hour")
    
    uptimePlot <- basePlot +
      scale_x_datetime(
        date_labels = "%b %d",
        date_breaks = "1 day",
        date_minor_breaks = "3 hours" # TODO:  Why aren't these showing?
      )
    
  } else {
    
    uptimePlot <- basePlot +
      scale_x_datetime(
        date_labels = "%b %d",
        date_breaks = "1 day"
      )
    
  }
  
  # ----- Save plot ------------------------------------------------------------
  
  ggsave(
    plotPath,
    plot = uptimePlot,
    width = width,
    height = height,
    dpi = dpi,
    units = units
  )
  
  return(invisible())
  
}
