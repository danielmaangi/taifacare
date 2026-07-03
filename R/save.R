#' Save a data frame to Excel or CSV
#'
#' Writes \code{data} to a formatted Excel workbook or a plain CSV file.
#' When \code{format = "auto"} (default), Excel is chosen for tables with up
#' to 10,000 rows and CSV for larger ones. The correct file extension is
#' appended automatically if the path does not already include one.
#'
#' Excel output includes a styled header row, frozen top row, and auto-fit
#' column widths. Data is written as-is with no pre-formatting.
#'
#' @param data A data frame to export.
#' @param path Character scalar. Destination file path (with or without
#'   extension).
#' @param format Character scalar. \code{"auto"} (default), \code{"excel"},
#'   or \code{"csv"}.
#'
#' @return The resolved file path, invisibly.
#'
#' @examples
#' \dontrun{
#'   con <- tc_connect()
#'   erp <- tc_fetch_erp(con)
#'
#'   tc_save(erp, "erp_claims")             # auto: excel (small table)
#'   tc_save(erp, "erp_claims", "csv")      # force CSV
#'   tc_save(erp, "erp_claims.xlsx")        # explicit path with extension
#'
#'   DBI::dbDisconnect(con)
#' }
#'
#' @export
#' @importFrom openxlsx createWorkbook addWorksheet writeData createStyle
#'   addStyle setColWidths freezePane saveWorkbook
tc_save <- function(data, path, format = c("auto", "excel", "csv")) {
  format <- match.arg(format)
  if (format == "auto") {
    format <- if (nrow(data) <= 10000) "excel" else "csv"
  }

  ext  <- if (format == "excel") ".xlsx" else ".csv"
  path <- if (!grepl("\\.(xlsx|csv)$", path, ignore.case = TRUE)) {
    paste0(path, ext)
  } else path

  if (format == "csv") {
    utils::write.csv(data, path, row.names = FALSE)
    message("Saved CSV: ", path)
    return(invisible(path))
  }

  n_rows <- nrow(data)
  n_cols <- ncol(data)

  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Data")
  openxlsx::writeData(wb, "Data", data, startRow = 1, startCol = 1)

  header_style <- openxlsx::createStyle(
    fontColour     = "#FFFFFF",
    fgFill         = "#1F5C7A",
    textDecoration = "bold",
    halign         = "left",
    border         = "Bottom",
    borderColour   = "#FFFFFF"
  )

  body_style <- openxlsx::createStyle(
    border       = "TopBottomLeftRight",
    borderColour = "#D9D9D9"
  )

  openxlsx::addStyle(wb, "Data", header_style,
                     rows = 1, cols = seq_len(n_cols), gridExpand = TRUE)

  if (n_rows > 0) {
    openxlsx::addStyle(wb, "Data", body_style,
                       rows = seq(2, n_rows + 1), cols = seq_len(n_cols),
                       gridExpand = TRUE)
  }

  openxlsx::setColWidths(wb, "Data", cols = seq_len(n_cols), widths = "auto")
  openxlsx::freezePane(wb, "Data", firstRow = TRUE)
  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)

  message("Saved Excel: ", path)
  invisible(path)
}
