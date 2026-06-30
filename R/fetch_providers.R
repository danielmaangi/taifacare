#' Fetch provider registry from ClickHouse
#'
#' Queries the provider registry table and returns facility identifiers,
#' names, and county information.
#'
#' @param con A DBI connection, typically from \code{\link{tc_connect}}.
#' @param schema Character scalar. Source schema name. Default:
#'   \code{"claim"}.
#' @param table Character scalar. Source table name. Default:
#'   \code{"provider_v2"}.
#'
#' @return A data frame with columns \code{pro_id}, \code{mfl},
#'   \code{pro_fid}, \code{pro_fid_code}, \code{provider_name}, and
#'   \code{county}.
#'
#' @seealso \code{\link{tc_fetch_old_erp}}, \code{\link{tc_fetch_new_erp}}
#'
#' @examples
#' \dontrun{
#'   con <- tc_connect()
#'   providers <- tc_fetch_providers(con)
#'   DBI::dbDisconnect(con)
#' }
#'
#' @export
#' @importFrom DBI dbGetQuery
#' @importFrom glue glue
tc_fetch_providers <- function(
  con,
  schema = "claim",
  table  = "provider_v2"
) {
  sql <- glue::glue("
    SELECT
      id       AS pro_id,
      mfl,
      fid      AS pro_fid,
      fid_code AS pro_fid_code,
      name     AS provider_name,
      county
    FROM {schema}.{table} FINAL
  ")

  DBI::dbGetQuery(con, sql)
}
