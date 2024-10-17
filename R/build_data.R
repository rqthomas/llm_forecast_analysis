library(tidyverse)
library(duckdb)


s3 <- arrow::s3_bucket("bio230121-bucket01/flare/forecasts/parquet/site_id=fcre/model_id=glm_aed_flare_v3",
                       endpoint_override = "renc.osn.xsede.org",
                       anonymous = TRUE)

df <- arrow::open_dataset(s3) |>
  filter(reference_datetime > as_date("2024-10-10") & reference_datetime < as_date("2024-10-12") ) |>
  dplyr::collect()

con <- dbConnect(duckdb(dbdir ="database.duckdb"))

duckdb::dbWriteTable(
  con
  ,"forecast"
  ,df
  ,overwrite = TRUE)

dbDisconnect(con)

