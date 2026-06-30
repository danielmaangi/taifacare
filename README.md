# taifacare

An R package for fetching, transforming, and analysing Universal Health Coverage (UHC) data from ClickHouse databases. It covers ERP payment claims (old and new pipelines) and the provider registry, with parameterised query functions and tidy summarisation helpers.

## Installation

```r
# Install from GitHub
devtools::install_github("danielmaangi/taifacare")
```

## Setup

Credentials are read from environment variables. Create a `.env` file in your project root (never commit this):

```
CLICKHOUSE_HOST=your-host
CLICKHOUSE_PORT=8123
CLICKHOUSE_USER=your-user
CLICKHOUSE_PASSWORD=your-password
```

Load them before connecting:

```r
dotenv::load_dot_env()
```

## Usage

### Connect

```r
library(taifacare)

con <- tc_connect()                        # uses env vars
con <- tc_connect(db = "production")       # switch database
```

### Fetch data

```r
# Provider registry
providers <- tc_fetch_providers(con)

# ERP payment claims
old_erp <- tc_fetch_old_erp(con)
new_erp <- tc_fetch_new_erp(con)

# Filter by state / payment status
old_erp <- tc_fetch_old_erp(con, states = c("done", "partial"), payment_statuses = "paid")
```

### Summarise

```r
# Total by fund scheme (default)
tc_erp_summary(old_erp, "old_erp_amount")

# Total by county and fund scheme
tc_erp_summary(old_erp, "old_erp_amount", group_col = c("county", "fund_scheme"))
```

### Disconnect

```r
DBI::dbDisconnect(con)
```

## Functions

| Function | Description |
|---|---|
| `tc_connect()` | Open a ClickHouse connection |
| `tc_fetch_providers()` | Fetch the provider registry |
| `tc_fetch_old_erp()` | Fetch old ERP payment claims |
| `tc_fetch_new_erp()` | Fetch new ERP (IFS) payment claims |
| `tc_erp_summary()` | Summarise claim amounts by group |

## Dependencies

- [DBI](https://dbi.r-dbi.org/)
- [ClickHouseHTTP](https://github.com/IMSMWU/RClickhouse)
- [dplyr](https://dplyr.tidyverse.org/)
- [glue](https://glue.tidyverse.org/)
