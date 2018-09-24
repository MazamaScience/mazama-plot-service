# Specficic packages and scripts for this service -----------------------------

# NOTE:  Use library() so that these package versions will be documented by
#        sessionInfo()
suppressPackageStartupMessages({
  library(methods)                # always included for Rscripts
  library(plumber)                # web service framework
  library(MazamaWebUtils)         # cache management
  library(digest)                 # creation of uniqueID
  library(stringr)                # manipulation of data in InfoList
  library(dplyr)                  # dataframe manipulations
  library(ggplot2)                # plotting
})

# ----- BEGIN jug app ---------------------------------------------------------

#* Return JSON description of this service
#* @get /plot-service/dev
#* @serializer unboxedJSON
function() {
  logger.info("----- %s -----", "/plot-service/dev")
  response <- createAPIList(SERVICE_PATH, VERSION)
}

#* Carry out a general plot subservice
#* http://localhost:8080/plot-service/dev/server-load?serverid=joule.mazamascience.com&lookbackdays=3
#* @get /plot-service/dev/<subservice>
#* @serializer contentType list(type='image/png')
function(subservice, req) {
  
  # Format subservice string to be lowercase
  
  logger.info("----- %s -----", subservice)
  
  # Create subservice script paths
  infoListScript <- paste0("R/", subservice, "/createInfoList.R")
  dataListScript <- paste0("R/", subservice, "/createDataList.R")
  productScript <- paste0("R/", subservice, "/createProduct.R")
  
  # Source these scripts
  result <- try({
    source(infoListScript)        # function to convert request into infoList required by product
    source(dataListScript)        # function to load data required by product
    source(productScript)         # function to create product
  }, silent = TRUE)
  stopOnError(result)
  
  params <- httr::parse_url(req$QUERY_STRING)
  req$params <- params$query
  
  # Create infoList
  result <- try({
    infoList <- createInfoList(req, CACHE_DIR)
  }, silent = TRUE)
  stopOnError(result)
  
  # Create a new plot file if it isn't in the cache
  if (!file.exists(infoList$plotPath)) {
    
    # Manage the cache
    MazamaWebUtils::manageCache(CACHE_DIR, c("json", "png", "pdf")) # TODO:  Other potential output formats?
    
    result <- try({

      # Get data and text for this product
      dataList <- createDataList(infoList, DATA_DIR)

      # Get language dependent plot labels
      textListScript <- paste(
        "R/", subservice, "/createTextList_", infoList$language, ".R",
        sep = "")
      source(textListScript)
      textList <- createTextList(dataList, infoList)

      # Create product
      createProduct(dataList, infoList, textList)

      logger.info("successfully created %s", infoList$plotPath)

    }, silent = TRUE)
    stopOnError(result)
    
  } # finished creating product file
  
  # Create a new json file if it isn't in the cache
  if (!file.exists(infoList$jsonPath)) {
    
    result <- try({
      
      logger.debug("writing %s", infoList$jsonPath)
      
      responseList <- list(
        status <- "OK",
        rel_base <- paste0(SERVICE_PATH, "/", infoList$basePath),
        plot_path <- paste0(SERVICE_PATH, "/", infoList$plotPath)
      )
      
      json <- jsonlite::toJSON(
        responseList,
        na = "null",
        pretty = TRUE,
        auto_unbox = TRUE)
      write(json, infoList$jsonPath)
      logger.info("successfully created %s", infoList$jsonPath)
      
    }, silent = TRUE)
    stopOnError(result)
    
  } # finished creating json file
  
  # Return the appropriate file based on infoList$responsetype
  result <- try({
    
    if (infoList$responsetype == "raw") {
      
      if (infoList$outputfiletype == "png") {
        #res$content_type("image/png")
      } else if (infoList$outputfiletype == "pdf") {
        #res$content_type("application/pdf")
      }
      
      logger.debug("HELP")
      return(readBin(infoList$plotPath,'raw',n = file.info(infoList$plotPath)$size))
      
    } else if (infoList$responsetype == "json") {
      
      #res$content_type("application/json")
      #return(readr::read_file(infoList$jsonPath))
      
    } else {
      
      err_msg <- paste0("Invalild responsetype: ", infoList$responsetype)
      stop(err_msg, call. = FALSE)
      
    }
    
  }, silent = TRUE)
  stopOnError(result)
}
