#' Fetch ERP payment claims from ClickHouse
#'
#' Queries old ERP, new ERP (IFS), or both claims tables and returns
#' aggregated claim amounts by facility and fund scheme. By default both
#' sources are fetched and joined on \code{fid_code} / \code{fund_scheme}.
#'
#' @param con A DBI connection, typically from \code{\link{tc_connect}}.
#' @param source Character scalar. Which source to fetch: \code{"both"}
#'   (default), \code{"old"}, or \code{"new"}.
#' @param payment_statuses Character vector of payment statuses to include.
#'   Default: \code{"paid"}.
#' @param states Character vector of claim states to include (old ERP only).
#'   Default: \code{"done"}.
#' @param old_table Character scalar. Old ERP table name. Default:
#'   \code{"account_payable_claims_test"}.
#' @param new_table Character scalar. New ERP (IFS) table name. Default:
#'   \code{"ifs_test"}.
#' @param schema Character scalar. Schema containing both tables. Default:
#'   \code{"erp"}.
#'
#' @return A data frame. When \code{source = "both"}, columns are
#'   \code{fid_code}, \code{fund_scheme}, \code{old_erp_amount}, and
#'   \code{new_erp_amount} (full join; NAs where a facility appears in only
#'   one source). When \code{source = "old"} or \code{"new"}, only the
#'   corresponding amount column is returned.
#'
#' @seealso \code{\link{tc_erp_summary}}
#'
#' @examples
#' \dontrun{
#'   con <- tc_connect()
#'
#'   erp <- tc_fetch_erp(con)                          # both sources
#'   erp <- tc_fetch_erp(con, source = "old")          # old ERP only
#'   erp <- tc_fetch_erp(con, source = "new", payment_statuses = "unpaid")
#'   erp <- tc_fetch_erp(con, states = c("done", "partial"))
#'
#'   DBI::dbDisconnect(con)
#' }
#'
#' @export
#' @importFrom DBI dbGetQuery
#' @importFrom glue glue
#' @importFrom dplyr full_join
tc_fetch_erp <- function(
  con,
  source           = c("both", "old", "new"),
  payment_statuses = "paid",
  states           = "done",
  old_table        = "account_payable_claims_test",
  new_table        = "ifs_test",
  schema           = "erp"
) {
  source               <- match.arg(source)
  payment_statuses_sql <- paste(sprintf("'%s'", payment_statuses), collapse = ", ")

  if (source %in% c("both", "old")) {
    states_sql <- paste(sprintf("'%s'", states), collapse = ", ")
    old_data   <- DBI::dbGetQuery(con, glue::glue("
      SELECT
        vendor_code AS fid_code,
        fund_scheme,
        sum(claim_amount) AS old_erp_amount
      FROM {schema}.{old_table} FINAL
      WHERE state IN ({states_sql})
        AND payment_status IN ({payment_statuses_sql})
      GROUP BY fid_code, fund_scheme
    "))
  }

  if (source %in% c("both", "new")) {
    new_data <- DBI::dbGetQuery(con, glue::glue("
      SELECT
        fid_code,
        fund_scheme,
        sum(claim_amount) AS new_erp_amount
      FROM {schema}.{new_table} FINAL
      WHERE payment_status IN ({payment_statuses_sql})
      GROUP BY fid_code, fund_scheme
    "))
  }

  switch(source,
    old  = old_data,
    new  = new_data,
    both = dplyr::full_join(old_data, new_data, by = c("fid_code", "fund_scheme"))
  )
}
