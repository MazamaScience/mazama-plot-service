########################################################################
# server-load/createDataList.R
#
# Create a list of data needed to generate the product.
#
# Author: Spencer Pease, Jonathan Callahan
########################################################################

createDataList <- function(
  infoList = NULL,
  dataDir = NULL
) {

  logger.debug("----- server-load/createDataList() -----")

  # ----- Validate parameters --------------------------------------------------

  MazamaCoreUtils::stopIfNull(infoList)

  # ----- Load uptime data ------------------------------------------------------------

  # NOTE:  Need to watch out for reboots that change the number of commas
  #
  # 2018-06-07 18:16:01 up 35 days, 59 min,  0 users,  load average: 0.05, 0.01, 0.09
  # 2018-06-07 18:31:01 up 1 min,  0 users,  load average: 3.70, 1.99, 0.76
  #
  # Sigh ... Why is nothing ever easy?

  serverProtocol <- infoList$serverprotocol
  serverID <- infoList$serverid
  startDate <- MazamaCoreUtils::parseDatetime(infoList$startdate, timezone = "UTC")

  ignoredIDs <- c( "tools-c12.airfire.org", "tools-c13.airfire.org")

  if ( serverID %in% ignoredIDs ) {
    stop(sprintf("ServerID %s is being ignored", serverID))
  }

  loadData = NULL

  result <- try({
    uptimeLogUrl <- paste0(serverProtocol, '://', serverID, '/logs/uptime.log')

    # Instead, load the data as lines for further parsing
    lines <- readr::read_lines(uptimeLogUrl)

    # Pull out elements using
    regex_datetime <- "([0-9]{4}-[0-9]{2}-[0-9]{2}.[0-9]{2}:[0-9]{2}:[0-9]{2})" # Either " " or "T" between ymd and hms
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
    fakeLines <- paste(datetimeString, usersString, loadString, sep = ",")
    # Omit any lines with "NA"
    fakeLines <- fakeLines[ !stringr::str_detect(fakeLines, "NA") ]
    fakeFile <- paste(fakeLines, collapse = "\n")

    loadData <- readr::read_csv(
      file = fakeFile,
      col_names = c('datetime', 'userCount', 'load_1_min', 'load_5_min', 'load_15_min'),
      col_types = "Tiddd"
    )

    # Use dplyr to filter
    loadData <-
      loadData %>%
      filter(datetime >= startDate)

  }, silent = TRUE)

  # Create dummy data to use if the uptime log is unavailible
  if ("try-error" %in% class(result)) {
    err_msg = geterrmessage()
    logger.trace(err_msg)
    loadData <- data.frame(Sys.time(), 0)
    colnames(loadData) <- c("datetime", "load_15_min")
  }

  # ----- Load free memory data --------------------------------------------------

  memoryData = NULL

  result <- try({
    memoryLogUrl <- paste0(serverProtocol, '://', serverID, '/logs/free_memory.log')
    col_names <- c('datetime','dummy','total','used','free','shared','buff_cache','available')
    memoryData <- readr::read_fwf(
      file = memoryLogUrl,
      col_positions = readr::fwf_empty(memoryLogUrl, col_names = col_names),
      col_types = "Tciiiiii"
    )
    memoryData$dummy <- NULL
    memoryData <-
      memoryData %>%
      # Add an "unavailable" column
      mutate(unavailable = total - available) %>%
      filter(datetime >= startDate)
  }, silent = TRUE)

  # Create dummy data to use if the memory log is unavailible
  if ("try-error" %in% class(result)) {
    err_msg <- geterrmessage()
    logger.trace(err_msg)
    memoryData <- data.frame(Sys.time(), 0, 0, 0, 0, 0, 0, 0)
    colnames(memoryData) <- c('datetime','dummy','total','used','free','shared','buff_cache','available')
  }

  # ----- Load disk usage data -------------------------------------------------

  # DO ubuntu
  # 2021-07-16T22:00:01+00:00 /dev/vda1       25226960 7087848  18122728  29% /
  # 2021-07-16T22:15:01+00:00 /dev/vda1       25226960 7516736  17693840  30% /
  # 2021-07-16T22:30:01+00:00 /dev/vda1       25226960 9543096  15667480  38% /
  # 2021-07-16T22:45:02+00:00 /dev/vda1       25226960 9733624  15476952  39% /

  # tools-c1.airfire.org
  # 2020-09-08T15:15:01+00:00 /dev/xvda1     130046416 58468340  71561692  45% /
  # 2020-09-08T15:30:01+00:00 /dev/xvda1     130046416 57108020  72922012  44% /
  # 2020-09-08T15:45:01+00:00 /dev/xvda1     130046416 57121196  72908836  44% /
  # 2020-09-08T16:00:01+00:00 /dev/xvda1     130046416 57149248  72880784  44% /


  diskData  = NULL

  result <- try({
    diskLogUrl <- paste0(serverProtocol, '://', serverID, '/logs/disk_usage.log')
    col_names <- c('datetime','dummy1','dummy2','dummy3','dummy4','used')
    diskData <- readr::read_fwf(
      file = diskLogUrl,
      col_positions = readr::fwf_positions(
        start = c(1,27,38,52,61,71),
        end = c(25,36,50,59,69,NA),
        col_names = col_names
      ),
      col_types = "Tciiic"
    )
    diskData <-
      diskData %>%
      filter(datetime >= startDate)
    diskData$used <-
      diskData$used %>%
      stringr::str_replace_all("%", "") %>%
      str_replace_all("/", "") %>%
      as.numeric()
    diskData$used <- diskData$used / 100
  }, silent = TRUE)

  # Create dummy data to use if the usage log is unavailible
  if ("try-error" %in% class(result)) {
    err_msg <- geterrmessage()
    logger.trace(err_msg)
    diskData <- data.frame(Sys.time(), 0)
    colnames(memoryData) <- c("datetime", "used")
  }

  # ----- Create data structures -----------------------------------------------

  # Create dataList
  dataList <- list(
    loadData = loadData,
    memoryData = memoryData,
    diskData = diskData
  )

  return(dataList)
}
