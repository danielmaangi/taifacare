#' Run an arbitrary SQL query against ClickHouse
#'
#' Generic escape hatch for ad-hoc SELECT statements against any table,
#' complementing the narrower \code{tc_fetch_*} functions.
#'
#' By default, queries are run with \code{format = "TabSeparatedWithNamesAndTypes"}
#' rather than the ClickHouseHTTP driver's default \code{"Arrow"} format.
#' Arrow cannot represent ClickHouse's \code{UUID} type and errors with
#' \code{"The type 'UUID' of a column ... is not supported for conversion
#' into Arrow data format"} on any query that selects one (including
#' \code{SELECT *}). \code{TabSeparatedWithNamesAndTypes} has no such
#' limitation and maps UUID columns to plain character strings. Pass
#' \code{format = "Arrow"} to opt back into the driver default for queries
#' known not to touch UUID columns.
#'
#' If \code{final = TRUE}, \code{FINAL} is appended to the first \code{FROM}
#' table reference (for ReplacingMergeTree deduplication), matching the
#' convention used by \code{\link{tc_fetch_providers}} and
#' \code{\link{tc_fetch_erp}}.
#'
#' @param con A DBI connection, typically from \code{\link{tc_connect}}.
#' @param sql Character scalar. A SELECT statement.
#' @param final Logical. Append FINAL to the queried table. Default: FALSE.
#' @param format Character scalar, passed to the ClickHouseHTTP driver.
#'   One of \code{"TabSeparatedWithNamesAndTypes"} (default) or
#'   \code{"Arrow"}.
#' @param ... Additional arguments passed to \code{DBI::dbGetQuery()}.
#'
#' @return A data frame.
#'
#' @seealso \code{\link{tc_fetch_providers}}, \code{\link{tc_fetch_erp}}
#'
#' @examples
#' \dontrun{
#'   con <- tc_connect()
#'   df <- tc_query(
#'     con,
#'     "SELECT claim_id, patient FROM claim.claims_v2 WHERE state = 'done'",
#'     final = TRUE
#'   )
#'   DBI::dbDisconnect(con)
#' }
#'
#' @export
#' @importFrom DBI dbGetQuery
tc_query <- function(
  con,
  sql,
  final  = FALSE,
  format = "TabSeparatedWithNamesAndTypes",
  ...
) {
  if (isTRUE(final)) {
    sql <- sub(
      "(?i)(\\bFROM\\s+[\\w.\"'`]+)(\\s+FINAL\\b)?",
      "\\1 FINAL",
      sql,
      perl = TRUE
    )
  }

  DBI::dbGetQuery(con, sql, format = format, ...)
}
