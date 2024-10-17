library(elmer)
library(tidyverse)
library(duckdb)

source("R/prompt-helper.R")

conn <- dbConnect(duckdb(), dbdir = here("database.duckdb"), read_only = TRUE)

system_prompt_str <- system_prompt(dbGetQuery(conn, "SELECT * FROM forecast"), "forecast")


chat <- chat_ollama(
  system_prompt = system_prompt_str,
  base_url = "http://localhost:11434/v1",
  model = "llama3.2"
)



query <- function(query) {
  df <- dbGetQuery(conn, query)
  df |> jsonlite::toJSON(auto_unbox = TRUE)
}

chat$register_tool(ToolDef(
  query,
  name = "query",
  description = "Perform a SQL query on the data, and return the results as JSON.",
  arguments = list(
    query = ToolArg(
      type = "string",
      description = "A DuckDB SQL query; must be a SELECT statement.",
      required = TRUE
    )
  )
))

chat$chat("What is the max prediction for the variable Temp_C_mean and variable type is state?")

q <- "SELECT MAX(prediction) FROM forecast WHERE variable_type = 'state' AND variable = 'Temp_C_mean'"
dbGetQuery(conn, q)


conn |>
  dbReadTable("forecast") |>
  as_tibble() |>
  filter(variable == "Temp_C_mean") |>
  summarize(max = max(prediction, na.rm = TRUE))
