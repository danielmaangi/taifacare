#' Check a column for invalid FID values
#'
#' A valid FID must contain the text \code{"FID"} (e.g.
#' \code{"FID-01-105224-1"}). This function flags rows where the specified
#' column is missing that text or is \code{NA}, and returns both the
#' offending rows and a count summary of the unique bad values found.
#'
#' @param data A data frame, typically from \code{\link{tc_fetch_erp}} or
#'   \code{\link{tc_fetch_providers}}.
#' @param col Character scalar. Name of the column to validate. Common
#'   values: \code{"fid_code"}, \code{"pro_fid_code"}, \code{"pro_fid"}.
#'
#' @return A named list:
#' \describe{
#'   \item{invalid_rows}{A data frame of rows where \code{col} failed
#'     validation. Zero rows if all values are valid.}
#'   \item{summary}{A data frame with columns \code{value} and \code{count}
#'     showing each unique invalid value and how many times it appears,
#'     sorted by \code{count} descending.}
#' }
#'
#' @examples
#' \dontrun{
#'   con <- tc_connect()
#'
#'   erp <- tc_fetch_erp(con)
#'   result <- tc_check_fids(erp, "fid_code")
#'   result$summary
#'   tc_save(result$invalid_rows, "bad_fids")
#'
#'   providers <- tc_fetch_providers(con)
#'   tc_check_fids(providers, "pro_fid_code")
#'
#'   DBI::dbDisconnect(con)
#' }
#'
#' @export
tc_check_fids <- function(data, col) {
  if (!col %in% names(data)) {
    stop(sprintf("Column '%s' not found in data.", col))
  }

  vals    <- data[[col]]
  invalid <- is.na(vals) | !grepl("FID", vals, fixed = TRUE)
  bad     <- data[invalid, , drop = FALSE]

  if (nrow(bad) == 0) {
    message("All FIDs in '", col, "' are valid.")
  } else {
    message(nrow(bad), " invalid FID(s) found in '", col, "'.")
  }

  counts <- as.data.frame(
    table(value = bad[[col]], useNA = "ifany"),
    stringsAsFactors = FALSE
  )
  names(counts)[2] <- "count"
  counts <- counts[order(-counts$count), ]
  rownames(counts) <- NULL

  list(invalid_rows = bad, summary = counts)
}
