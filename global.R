# Global configuration for Shiny application
# This file is sourced before ui.R and server.R

# Load required libraries
library(shiny)
library(shinydashboard)
library(DBI)
library(RMariaDB)
library(pool)
library(DT)
library(ggplot2)
library(dplyr)
library(lubridate)

# Database configuration
# Use environment variables in production
DB_CONFIG <- list(
  host = Sys.getenv("DB_HOST", "127.0.0.1"),
  dbname = Sys.getenv("DB_NAME", "bps_progress"),
  user = Sys.getenv("DB_USER", "bps_user"),
  password = Sys.getenv("DB_PASSWORD", ""),
  port = as.integer(Sys.getenv("DB_PORT", "3306"))
)

# Create database connection pool
create_db_pool <- function() {
  tryCatch({
    pool <- dbPool(
      drv = RMariaDB::MariaDB(),
      dbname = DB_CONFIG$dbname,
      host = DB_CONFIG$host,
      user = DB_CONFIG$user,
      password = DB_CONFIG$password,
      port = DB_CONFIG$port
    )
    
    # Test connection
    con <- poolCheckout(pool)
    tables <- dbListTables(con)
    poolReturn(con)
    
    if (length(tables) == 0) {
      warning("Database connected but no tables found. Please run database_schema.sql")
    }
    
    return(pool)
  }, error = function(e) {
    stop(paste("Database connection failed:", e$message))
  })
}

# Global variables
APP_VERSION <- "1.0.0"
APP_NAME <- "SI-PRIMA Dashboard"

# Utility functions
format_date <- function(date) {
  if (is.na(date) || is.null(date)) return("N/A")
  format(as.Date(date), "%d/%m/%Y")
}

format_datetime <- function(datetime) {
  if (is.na(datetime) || is.null(datetime)) return("N/A")
  format(as.POSIXct(datetime), "%d/%m/%Y %H:%M")
}

# Close pool on app exit
onStop(function() {
  if (exists("pool") && !is.null(pool)) {
    poolClose(pool)
  }
})
