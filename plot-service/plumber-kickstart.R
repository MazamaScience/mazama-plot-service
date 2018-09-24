utilFiles <- list.files("R/sharedUtils", pattern = ".+\\.R", full.names = TRUE)

for (file in utilFiles) {
  source(file.path(getwd(), file))
}

VERSION <- "1.0.0"

if (Sys.getenv("PLUMBER_HOST") == "") {
  # plumber instance configuration
  PLUMBER_HOST <- "127.0.0.1" # plumber default
  PLUMBER_PORT <- "8080"      # plumber default
  
  # Path and cache
  SERVICE_PATH <- "plot-service/dev"
  CACHE_SIZE <- 100 # megabytes
  
  # Directories for log output, data, and cache
  DATA_DIR <- file.path(getwd(), "data")
  if (!file.exists(DATA_DIR)) dir.create(DATA_DIR)
  LOG_DIR <- file.path(getwd(), "logs")
  if (!file.exists(LOG_DIR)) dir.create(LOG_DIR)
  CACHE_DIR <- file.path(getwd(), "output")
  if (!file.exists(CACHE_DIR)) dir.create(CACHE_DIR)
  
  # Clean out the cache (only when running from RStudio)
  removalStatus <- file.remove( list.files(CACHE_DIR, full.names = TRUE) )
} else {
  # Running from Docker
}

# Silence other warning messages
options(warn = -1) # -1=ignore, 0=save/print, 1=print, 2=error

# ----- Set up Logging --------------------------------------------------------

result <- try({
  # Copy and old log files
  timestamp <- strftime(lubridate::now(), "%Y-%m-%dT%H:%M:%S")
  for ( logLevel in c("TRACE","DEBUG","INFO","ERROR") ) {
    oldFile <- file.path(LOG_DIR,paste0(logLevel,".log"))
    newFile <- file.path(LOG_DIR,paste0(logLevel,".log.",timestamp))
    if ( file.exists(oldFile) ) {
      file.rename(oldFile, newFile)
    }
  }
}, silent=TRUE)
stopOnError(result, "Could not rename old log files.")

result <- try({
  # Set up logging
  logger.setup(traceLog = file.path(LOG_DIR, "TRACE.log"),
               debugLog = file.path(LOG_DIR, "DEBUG.log"),
               infoLog = file.path(LOG_DIR, "INFO.log"),
               errorLog = file.path(LOG_DIR, "ERROR.log"))
}, silent = TRUE)
stopOnError(result, "Could not create log files.")

if (Sys.getenv("PLUMBER_HOST") == "") { # Running from RStudio
  logger.setLevel(TRACE)            # send error messages to console (RStudio)
}

# Capture session info
logger.debug(capture.output(sessionInfo()))

# Log environment variables
logger.debug('PLUMBER_HOST = %s', PLUMBER_HOST)
logger.debug('PLUMBER_PORT = %s', PLUMBER_PORT)
logger.debug('SERVICE_PATH = %s', SERVICE_PATH)
logger.debug('CACHE_DIR = %s', CACHE_DIR)
logger.debug('CACHE_SIZE = %s', CACHE_SIZE)
logger.debug('DATA_DIR = %s', DATA_DIR)
logger.debug('LOG_DIR = %s', LOG_DIR)

# ----- BEGIN jug app ---------------------------------------------------------

r <- plumb("plumber-service.R")
r$run(port = 8080)