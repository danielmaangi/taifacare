#' Summarise ERP claim amounts by fund scheme
#'
#' Groups a data frame by one or more columns and sums an amount column,
#' returning one row per group. Works with both old-ERP and new-ERP data
#' frames returned by the \code{tc_fetch_*()} functions.
#'
#' @param data A data frame, typically from \code{\link{tc_fetch_erp}}.
#' @param amount_col Character scalar. Name of the column to sum.
#' @param group_col Character scalar or vector. Grouping column(s). Default:
#'   \code{"fund_scheme"}.
#'
#' @return An ungrouped data frame with one row per group and the summed
#'   amount in a column with the same name as \code{amount_col}.
#'
#' @examples
#' \dontrun{
#'   con <- tc_connect()
#'   erp <- tc_fetch_erp(con, source = "old")
#'   tc_erp_summary(erp, "old_erp_amount")
#'   tc_erp_summary(erp, "old_erp_amount", group_col = c("county", "fund_scheme"))
#'   DBI::dbDisconnect(con)
#' }
#'
#' @export
#' @importFrom dplyr group_by summarise across all_of
tc_erp_summary <- function(data, amount_col, group_col = "fund_scheme") {
  data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_col))) |>
    dplyr::summarise(
      dplyr::across(dplyr::all_of(amount_col), \(x) sum(x, na.rm = TRUE)),
      .groups = "drop"
    )
}


#' Monthly paid ERP claims by fund scheme
#'
#' Queries old ERP, new ERP (IFS), or both and returns a wide table of
#' total paid claim amounts by calendar month and fund scheme, with a
#' grand total column. Old ERP dates use \code{ceo_approval_date}; new ERP
#' dates use \code{payment_date}.
#'
#' @param con A DBI connection, typically from \code{\link{tc_connect}}.
#' @param source Character scalar. \code{"both"} (default), \code{"old"},
#'   or \code{"new"}.
#' @param payment_statuses Character vector. Default: \code{"paid"}.
#' @param states Character vector. Claim states (old ERP only). Default:
#'   \code{"done"}.
#' @param old_table Character scalar. Default:
#'   \code{"account_payable_claims_test"}.
#' @param new_table Character scalar. Default: \code{"ifs_test"}.
#' @param schema Character scalar. Default: \code{"erp"}.
#'
#' @return A data frame with one row per month. Columns: \code{month},
#'   one column per fund scheme (0 where no claims), and \code{total}.
#'   Arranged by \code{month} ascending.
#'
#' @seealso \code{\link{tc_fetch_erp}}, \code{\link{tc_erp_summary}}
#'
#' @examples
#' \dontrun{
#'   con <- tc_connect()
#'   tc_erp_monthly(con)
#'   tc_erp_monthly(con, source = "new")
#'   DBI::dbDisconnect(con)
#' }
#'
#' @export
#' @importFrom DBI dbGetQuery
#' @importFrom glue glue
#' @importFrom dplyr bind_rows summarise arrange
#' @importFrom tidyr pivot_wider
tc_erp_monthly <- function(
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

  parts <- list()

  if (source %in% c("both", "old")) {
    states_sql <- paste(sprintf("'%s'", states), collapse = ", ")
    parts$old  <- DBI::dbGetQuery(con, glue::glue("
      SELECT
        toStartOfMonth(ceo_approval_date) AS month,
        fund_scheme,
        sum(claim_amount)                 AS amount
      FROM {schema}.{old_table} FINAL
      WHERE state IN ({states_sql})
        AND payment_status IN ({payment_statuses_sql})
      GROUP BY month, fund_scheme
    "))
  }

  if (source %in% c("both", "new")) {
    parts$new <- DBI::dbGetQuery(con, glue::glue("
      SELECT
        toStartOfMonth(payment_date) AS month,
        fund_scheme,
        sum(claim_amount)            AS amount
      FROM {schema}.{new_table} FINAL
      WHERE payment_status IN ({payment_statuses_sql})
      GROUP BY month, fund_scheme
    "))
  }

  long <- dplyr::bind_rows(parts) |>
    dplyr::summarise(amount = sum(amount, na.rm = TRUE),
                     .by = c(month, fund_scheme))

  wide <- tidyr::pivot_wider(long,
    names_from  = fund_scheme,
    values_from = amount,
    values_fill = 0
  )

  wide$total <- rowSums(wide[setdiff(names(wide), "month")], na.rm = TRUE)

  dplyr::arrange(wide, month)
}
