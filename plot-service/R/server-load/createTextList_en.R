########################################################################
# server-load/textList_en.R
#
# English language text strings.
#
# Author: Jonathan Callahan
########################################################################

createTextList <- function(
  dataList = NULL, 
  infoList = NULL
) {
  
  logger.debug("----- server-load/createTextList() -----")
  
  # ----- Validate parameters --------------------------------------------------
  
  MazamaCoreUtils::stopIfNull(dataList)
  MazamaCoreUtils::stopIfNull(infoList)
  
  # ----- Create textList ------------------------------------------------------
  
  # Commonly used labels
  textList <- list()
  
  return(textList)
}
