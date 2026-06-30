#' Connect to a ClickHouse database
#'
#' Opens a DBI connection to a ClickHouse instance using the ClickHouseHTTP
#' driver. By default all credentials are read from environment variables so
#' that no secrets appear in source code.
#'
#' @param host Character scalar. ClickHouse host name or IP address. Defaults
#'   to the value of the \code{CLICKHOUSE_HOST} environment variable.
#' @param port Integer scalar. HTTP port. Defaults to \code{CLICKHOUSE_PORT}
#'   (coerced to integer).
#' @param user Character scalar. Database user name. Defaults to
#'   \code{CLICKHOUSE_USER}.
#' @param password Character scalar. Database password. Defaults to
#'   \code{CLICKHOUSE_PASSWORD}.
#' @param db Character scalar. Database to connect to. Defaults to
#'   \code{"development"}.
#'
#' @return A \code{\link[DBI]{DBIConnection}} object that can be passed to any
#'   \code{tc_fetch_*()} function.
#'
#' @seealso \code{\link{tc_fetch_old_erp}}, \code{\link{tc_fetch_new_erp}},
#'   \code{\link{tc_fetch_providers}}
#'
#' @examples
#' \dontrun{
#'   con <- tc_connect()
#'   con <- tc_connect(db = "production")
#'   DBI::dbDisconnect(con)
#' }
#'
#' @export
#' @importFrom DBI dbConnect
#' @importFrom ClickHouseHTTP ClickHouseHTTP
tc_connect <- function(
  host     = NULL,
  port     = NULL,
  user     = NULL,
  password = NULL,
  db       = "development"
) {
  if (!nzchar(Sys.getenv("CLICKHOUSE_HOST")) && file.exists(".env")) {
    dotenv::load_dot_env()
  }

  if (is.null(host))     host     <- Sys.getenv("CLICKHOUSE_HOST")
  if (is.null(port))     port     <- as.integer(Sys.getenv("CLICKHOUSE_PORT"))
  if (is.null(user))     user     <- Sys.getenv("CLICKHOUSE_USER")
  if (is.null(password)) password <- Sys.getenv("CLICKHOUSE_PASSWORD")

  if (!nzchar(host)) stop("CLICKHOUSE_HOST is not set. Add it to your .env file or set it with Sys.setenv().")
  if (!nzchar(user)) stop("CLICKHOUSE_USER is not set. Add it to your .env file or set it with Sys.setenv().")

  DBI::dbConnect(
    ClickHouseHTTP::ClickHouseHTTP(),
    host     = host,
    port     = port,
    user     = user,
    password = password,
    db       = db
  )
}
