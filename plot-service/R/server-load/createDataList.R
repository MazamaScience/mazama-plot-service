########################################################################
# uptime/createDataList.R
#
# Create a list of data needed to generate the product.
#
# Author: Spencer Pease, Jonathan Callahan
########################################################################

createDataList <- function(infoList = NULL, dataDir = NULL) {

  logger.trace("----- createDataList() -----")

  if (is.null(infoList)) stop(paste0("Required parameter 'infoList' is missing."), call. = FALSE)

  # ----- Load data -----------------------------------------------------------

  # NOTE:  Need to watch out for reboots that change the number of commas
  #
  # 2018-06-07 18:16:01 up 35 days, 59 min,  0 users,  load average: 0.05, 0.01, 0.09
  # 2018-06-07 18:31:01 up 1 min,  0 users,  load average: 3.70, 1.99, 0.76
  #
  # Sigh ... Why is nothing ever easy?
  
  serverID <- infoList$serverid
  startDate <- lubridate::ymd_hm(infoList$startdate) # NOTE:  only to the minute, not second
  
  uptimeData = NULL
  
  result <- try({
    uptimeLogUrl <- paste0('https://', serverID, '.airfire.org/logs/uptime.log')
    
    # Instead, load the data as lines for further parsing
    lines <- readr::read_lines(uptimeLogUrl)
    
    # Pull out elements using
    regex_datetime <- "([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})"
    datetimeString <- stringr::str_extract(lines, regex_datetime)
    
    regex_users <- "([0-9]+ user.?,)"
    usersString <- stringr::str_extract(lines, regex_users)
    # For userCount, use everything to the left of the first ' '
    usersString = stringr::str_split_fixed(usersString, ' ', 2)[,1]
    
    regex_load <- "(load average: .+$)"
    loadString <- stringr::str_extract(lines, regex_load)
    loadString <- stringr::str_replace(loadString, "load average: ", "")
    loadString <- stringr::str_replace_all(loadString, " ", "")
    
    # Now reassemble a cleaned up, artificial CSV file 
    fakeLines <- paste(datetimeString, usersString, loadString, sep=",")
    # Omit any lines with "NA"
    fakeLines <- fakeLines[ !stringr::str_detect(fakeLines, "NA") ]
    fakeFile <- paste(fakeLines, collapse="\n")
    
    uptimeData <- readr::read_csv(fakeFile,
                                  col_names = c('datetime', 'userCount', 'load_1_min', 'load_5_min', 'load_15_min'))
    
    # Use dplyr to filter
    uptimeData <-
      uptimeData %>%
      filter(datetime >= startDate)
  }, silent = TRUE)
  
  # Create dummy data to use if the uptime log is unavailible 
  if ("try-error" %in% class(result)) {
    err_msg = geterrmessage()
    logger.trace(err_msg)
    uptimeData <- data.frame(Sys.time(), 0)
    colnames(uptimeData) <- c("datetime", "load_15_min")
  }

  # ----- Validate data -------------------------------------------------------

  # ----- Load 'free -h' data -------------------------------------------------
  
  memoryData = NULL
  
  result <- try({
    memoryLogUrl <- paste0('https://', serverID, '.airfire.org/logs/free_memory.log')
    col_names <- c('datetime','dummy','total','used','free','shared','buff_cache','available')
    memoryData <- readr::read_fwf(memoryLogUrl, readr::fwf_empty(memoryLogUrl, col_names=col_names))
    memoryData$dummy <- NULL
    
    memoryData <-
      memoryData %>%
      filter(datetime >= startDate)
  }, silent=TRUE)
  
  # Create dummy data to use if the memory log is unavailible 
  if ("try-error" %in% class(result)) {
    err_msg <- geterrmessage()
    logger.trace(err_msg)
    memoryData <- data.frame(Sys.time(), 0, 0)
    colnames(memoryData) <- c("datetime", "total", "used")
  }

  # ----- Create data structures ----------------------------------------------

  # Create dataList
  dataList <- list(
    uptimeData = uptimeData,
    memoryData = memoryData
  )
  
  return(dataList)
}
