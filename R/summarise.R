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
