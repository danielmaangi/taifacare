#' Glimpse a data frame
#'
#' Thin wrapper around \code{dplyr::glimpse()} for consistent \code{tc_}
#' naming. Operates on data already loaded into R (e.g. the result of
#' \code{\link{tc_query}} or one of the \code{tc_fetch_*} functions) — it
#' does not query ClickHouse itself.
#'
#' @param x A data frame.
#' @param width Passed to \code{dplyr::glimpse()}.
#' @param ... Additional arguments passed to \code{dplyr::glimpse()}.
#'
#' @return Invisibly returns \code{x} (same as \code{dplyr::glimpse()}).
#'
#' @seealso \code{\link{tc_query}}
#'
#' @examples
#' \dontrun{
#'   con <- tc_connect()
#'   df <- tc_query(con, "SELECT * FROM claim.claims_v2 LIMIT 100")
#'   tc_glimpse(df)
#'   DBI::dbDisconnect(con)
#' }
#'
#' @export
#' @importFrom dplyr glimpse
tc_glimpse <- function(x, width = NULL, ...) {
  dplyr::glimpse(x, width = width, ...)
}
