#' Fetch old ERP payment claims from ClickHouse
#'
#' Queries the old ERP claims table and returns aggregated claim amounts by
#' facility and fund scheme, filtered by claim state and payment status.
#'
#' @param con A DBI connection, typically from \code{\link{tc_connect}}.
#' @param states Character vector of claim states to include. Default:
#'   \code{"done"}.
#' @param payment_statuses Character vector of payment statuses to include.
#'   Default: \code{"paid"}.
#' @param schema Character scalar. Source schema name. Default: \code{"erp"}.
#' @param table Character scalar. Source table name. Default:
#'   \code{"account_payable_claims_test"}.
#'
#' @return A data frame with columns \code{fid_code}, \code{fund_scheme}, and
#'   \code{old_erp_amount}.
#'
#' @seealso \code{\link{tc_fetch_new_erp}}, \code{\link{tc_erp_summary}}
#'
#' @examples
#' \dontrun{
#'   con <- tc_connect()
#'   old_erp <- tc_fetch_old_erp(con)
#'   old_erp <- tc_fetch_old_erp(con, states = c("done", "partial"))
#'   DBI::dbDisconnect(con)
#' }
#'
#' @export
#' @importFrom DBI dbGetQuery
#' @importFrom glue glue
tc_fetch_old_erp <- function(
  con,
  states           = "done",
  payment_statuses = "paid",
  schema           = "erp",
  table            = "account_payable_claims_test"
) {
  states_sql           <- paste(sprintf("'%s'", states),           collapse = ", ")
  payment_statuses_sql <- paste(sprintf("'%s'", payment_statuses), collapse = ", ")

  sql <- glue::glue("
    SELECT
      vendor_code AS fid_code,
      fund_scheme,
      sum(claim_amount) AS old_erp_amount
    FROM {schema}.{table} FINAL
    WHERE state IN ({states_sql})
      AND payment_status IN ({payment_statuses_sql})
    GROUP BY fid_code, fund_scheme
  ")

  DBI::dbGetQuery(con, sql)
}


#' Fetch new ERP payment claims from ClickHouse
#'
#' Queries the new ERP (IFS) claims table and returns aggregated claim amounts
#' by facility and fund scheme, filtered by payment status.
#'
#' @param con A DBI connection, typically from \code{\link{tc_connect}}.
#' @param payment_statuses Character vector of payment statuses to include.
#'   Default: \code{"paid"}.
#' @param schema Character scalar. Source schema name. Default: \code{"erp"}.
#' @param table Character scalar. Source table name. Default:
#'   \code{"ifs_test"}.
#'
#' @return A data frame with columns \code{fid_code}, \code{fund_scheme}, and
#'   \code{new_erp_amount}.
#'
#' @seealso \code{\link{tc_fetch_old_erp}}, \code{\link{tc_erp_summary}}
#'
#' @examples
#' \dontrun{
#'   con <- tc_connect()
#'   new_erp <- tc_fetch_new_erp(con)
#'   DBI::dbDisconnect(con)
#' }
#'
#' @export
#' @importFrom DBI dbGetQuery
#' @importFrom glue glue
tc_fetch_new_erp <- function(
  con,
  payment_statuses = "paid",
  schema           = "erp",
  table            = "ifs_test"
) {
  payment_statuses_sql <- paste(sprintf("'%s'", payment_statuses), collapse = ", ")

  sql <- glue::glue("
    SELECT
      fid_code,
      fund_scheme,
      sum(claim_amount) AS new_erp_amount
    FROM {schema}.{table} FINAL
    WHERE payment_status IN ({payment_statuses_sql})
    GROUP BY fid_code, fund_scheme
  ")

  DBI::dbGetQuery(con, sql)
}
