########################################################################
# server-load/createInfoList.R
#
# Create an infoList from a beakr request object.
#
# Besides basic conversion from strings to other data types, a lot of
# specific choices can made here that will be used later on in different
# plotting scripts.
#
# Author: Spencer Pease, Jonathan Callahan
########################################################################

createInfoList <- function(
  req = NULL,
  cacheDir = NULL
) {

  logger.debug("----- server-load/createInfoList() -----")

  # ----- Validate parameters --------------------------------------------------

  MazamaCoreUtils::stopIfNull(req)
  MazamaCoreUtils::stopIfNull(cacheDir)

  # Initialize the infoList from the request parameters
  infoList <- req$parameters
  names(infoList) <- tolower(names(infoList))

  logger.debug("req$parameters")
  logger.debug(capture.output(str(req$parameters)))

  # ----- Check for required parameters ----------------------------------------

  MazamaCoreUtils::stopIfNull(infoList$serverid)

  # ----- Set parameter defaults -----------------------------------------------

  # Set defaults
  infoList$serverprotocol <- tolower(ifelse(is.null(infoList$serverprotocol), "https", infoList$serverprotocol))
  infoList$serverid <- tolower(infoList$serverid)
  # NOTE:  During plotting, ymax will take the maximum of the data maximum or infoList$ymax
  # NOTE:  We default to a small number so that data maximum will be used unless the users specifies something larger
  infoList$ymax <- ifelse(is.null(infoList$ymax), .01, as.numeric(infoList$ymax))

  infoList$language <- tolower(ifelse(is.null(infoList$language),"en", infoList$language))
  infoList$responsetype <- tolower(ifelse(is.null(infoList$responsetype), "raw", infoList$responsetype))
  infoList$lookbackdays <- ifelse(is.null(infoList$lookbackdays), 3, trunc(as.numeric(infoList$lookbackdays)))

  infoList$outputfiletype <- ifelse(is.null(infoList$outputfiletype), "png", infoList$outputfiletype)

  infoList$width <- ifelse(is.null(infoList$width), 10, as.numeric(infoList$width))
  infoList$height <- ifelse(is.null(infoList$height), 6, as.numeric(infoList$height))
  infoList$units <- ifelse(is.null(infoList$units), "in", infoList$units)
  infoList$dpi <- ifelse(is.null(infoList$dpi), 100, as.numeric(infoList$dpi))

  # Validate parameters
  if (!infoList$language %in% c("en","es")) { stop("invalid language", call. = FALSE) }
  if (!infoList$responsetype %in% c("raw", "json")) { stop("invalid responsetype", call. = FALSE) }
  if (!infoList$outputfiletype %in% c("png", "pdf")) { stop("invalid file format", call. = FALSE) }
  if (!infoList$units %in% c("in", "cm", "mm")) { stop("invalid units", call. = FALSE) }
  if (infoList$lookbackdays < 2 ) { infoList$lookbackdays <- 2 }

  # NOTE:  enddate is specified here for creating the uniqueList. Enddate for plotting is specified
  # NOTE:  in the plotting function using localTime to set the default.

  if ( is.null(infoList$enddate) ) {
    infoList$enddate <- strftime(lubridate::now(tzone = "UTC"), format = "%Y%m%d%H%M", tz = "UTC")
  }

  if ( is.null(infoList$startdate) ) {
    endtime <- MazamaCoreUtils::parseDatetime(infoList$enddate, timezone = "UTC")
    starttime <- endtime - lubridate::ddays(infoList$lookbackdays)
    infoList$startdate <- strftime(starttime, format = "%Y%m%d%H%M", tz = "UTC")
  }

  # TODO:  Could validate times and order at this point

  # ----- Create uniqueID based on parameters that affect the presentation -----

  # Update timestamp once every 5 minutes to guarantee plenty of cache hits
  timestamp <-
    lubridate::now(tzone = "UTC") %>%
    lubridate::floor_date("5 mins") %>%
    strftime("%Y%m%d%H%M")

  # TODO: handle creating unique plots for shorter time intervals
  uniqueList <- list(
    infoList$language,
    infoList$outputfiletype,
    infoList$height,
    infoList$width,
    infoList$dpi,
    infoList$serverid,
    infoList$ymax,
    infoList$lookbackdays,
    timestamp
  )

  infoList$uniqueID <- digest::digest(uniqueList, algo = "md5")

  # Create paths
  infoList$basePath <- paste0(cacheDir, "/", infoList$uniqueID)
  infoList$plotPath <- paste0(infoList$basePath, ".", infoList$outputfiletype)
  infoList$jsonPath <- paste0(infoList$basePath, ".json")

  return(infoList)

}

# ===== DEBUGGING ==============================================================

if ( FALSE ) {

  library(MazamaCoreUtils)
  logger.setup()
  logger.setLevel(TRACE)

  req <- list(
    parameters = list(
      serverid = "joule.mazamascience.com",
      lookbackdays = "3"
    )
  )

  cacheDir = "~/Projects/MazamaScience/mazama-plot-service/plot-service/output"

}


