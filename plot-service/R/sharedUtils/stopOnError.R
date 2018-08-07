########################################################################
# utils/stopOnError.R
#
# Error handling function.
#
# Author: Spencer Pease, Jonathan Callahan
########################################################################

stopOnError <- function(result,
                        err_msg = "") {
  
  if ( "try-error" %in% class(result) ) {
    
    # Use passed in message or cleaned up version from geterrmessage()
    err_msg <- ifelse(err_msg == "", geterrmessage(), err_msg)
    err_msg <- stringr::str_trim(err_msg)
    logger.error(err_msg)
    
    # TODO:  Convert opaque R error messages to something more friendly
    if ( stringr::str_detect(err_msg, "HARD TO UNDERSTAND ERROR MESSAGE") ) {
      stop("Simple error message.", call. = FALSE)
    } else {
      stop(stringr::str_replace(err_msg, "Error : ", ""), call. = FALSE)
    }
    
  }
  
}


