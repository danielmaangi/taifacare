#' Execute a fire-and-forget SQL statement
#'
#' @param con A DBI connection.
#' @param sql Character scalar. SQL to execute (DDL, DML, etc.).
#'
#' @return Invisibly returns \code{NULL}.
#' @noRd
#' @importFrom DBI dbSendQuery dbClearResult
ch_execute <- function(con, sql) {
  res <- DBI::dbSendQuery(con, sql)
  DBI::dbClearResult(res)
  invisible(NULL)
}
