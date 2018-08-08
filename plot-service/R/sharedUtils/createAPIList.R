########################################################################
# createAPIList.R
#
# Document the webservice API.
#
# Author: Spencer Pease, Jonathan Callahan
########################################################################

createAPIList <- function(name=NULL, version=NULL) {

  logger.debug("----- createAPIList() -----")

  if ( is.null(name) ) stop(paste0("Required parameter 'name' is missing."), call. = FALSE)
  if ( is.null(version) ) stop(paste0("Required parameter 'version' is missing."), call. = FALSE)

  # Service definition to be desplayed as JSON when no UI exists
  APIList <- list(
    name = "plot-service",
    version = version,
    services = list(
      "server-load" = list(
        method = "GET",
        params = list(
          serverid = "host name [default = 'joule.mazamascience.com']",
          ymax = "y-axis maximum [default = 1000]",
          width =  "width of the graphic in given units [default = 10]",
          height = "height of the graphic in given units [default = 6]",
          dpi = "dpi (in pixels per unit) of the graphic [default = 100]",
          units = "units to determine graphic size [default = in; in|cm|mm]",
          outputfiletype = "file type of the output graphic [default = png; png|pdf]",
          responsetype = "response type [default = raw; raw|json]",
          lookbackdays = "days of data to include [default = 7, max=45]",
          language = "[not implemented] language code [default = en; en|es]"
        )
      )
    ) # END of services list
  ) # END of APIList

  return(APIList)
}
