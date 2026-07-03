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

`tc_connect()` loads `.env` automatically if `CLICKHOUSE_HOST` is not already set, so no manual setup step is needed.

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

# ERP payment claims — both sources by default (full join)
erp <- tc_fetch_erp(con)

# One source only
erp <- tc_fetch_erp(con, source = "old")
erp <- tc_fetch_erp(con, source = "new")

# Filter by payment status or claim state (state applies to old ERP only)
erp <- tc_fetch_erp(con, payment_statuses = "unpaid")
erp <- tc_fetch_erp(con, source = "old", states = c("done", "partial"))
```

### Summarise

```r
# Total by fund scheme (default)
tc_erp_summary(erp, "old_erp_amount")

# Total by county and fund scheme
tc_erp_summary(erp, "old_erp_amount", group_col = c("county", "fund_scheme"))

# Monthly totals — wide table with one column per fund scheme + total
tc_erp_monthly(con)                      # both sources
tc_erp_monthly(con, source = "old")
tc_erp_monthly(con, source = "new", payment_statuses = "unpaid")
```

### Save output

```r
tc_save(erp, "erp_claims")              # auto: excel for small tables, csv for large
tc_save(erp, "erp_claims", "csv")       # force CSV
tc_save(erp, "erp_claims", "excel")     # force Excel
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
| `tc_fetch_erp()` | Fetch ERP claims (old, new, or both) |
| `tc_erp_summary()` | Summarise claim amounts by group |
| `tc_erp_monthly()` | Wide table of paid claims by month and fund scheme |
| `tc_save()` | Export a data frame to formatted Excel or CSV |

## Dependencies

- [DBI](https://dbi.r-dbi.org/)
- [ClickHouseHTTP](https://github.com/IMSMWU/RClickhouse)
- [dotenv](https://github.com/gaborcsardi/dotenv)
- [dplyr](https://dplyr.tidyverse.org/)
- [glue](https://glue.tidyverse.org/)
- [tidyr](https://tidyr.tidyverse.org/)
- [openxlsx](https://ycphs.github.io/openxlsx/)
