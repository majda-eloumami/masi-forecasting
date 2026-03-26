# =============================================================================
# MASI Index Forecasting — Script 01: Data Preparation
# Author: El Oumami Majda
# Description: Loads, cleans, and prepares the MASI dataset for modeling.
#              Performs stationarity tests and first-order differencing.
# =============================================================================

# --- 1. Package Management ---------------------------------------------------

required_packages <- c(
  "tidyverse", "lubridate", "xts", "zoo",
  "tseries", "forecast", "ggplot2"
)

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
  library(pkg, character.only = TRUE)
}

invisible(lapply(required_packages, install_if_missing))

# --- 2. Load Data ------------------------------------------------------------

# Set the path relative to project root (update if needed)
setwd("C:/Users/Lenovo/Desktop/masi-forecasting")
data_path <- "data/raw/MASI_DATA.csv"
masi_raw <- read.csv(data_path, stringsAsFactors = FALSE)

cat("=== Raw Data Structure ===\n")
str(masi_raw)

# --- 3. Clean and Format Columns ---------------------------------------------

masi <- masi_raw %>%
  mutate(
    Date    = as.Date(Date, format = "%m/%d/%Y"),
    Price   = as.numeric(gsub(",", "", Price)),
    Open    = as.numeric(gsub(",", "", Open)),
    High    = as.numeric(gsub(",", "", High)),
    Low     = as.numeric(gsub(",", "", Low)),
    Change  = as.numeric(gsub("%", "", Change..)) / 100
  ) %>%
  select(-Vol., -Change..) %>%   # Drop volume (missing) and raw Change col
  arrange(Date)                   # Ensure chronological order

cat("\n=== Cleaned Data Summary ===\n")
summary(masi)

# --- 4. Convert to Time Series Object ----------------------------------------

price_ts <- xts(masi$Price, order.by = masi$Date)

# --- 5. Train / Test Split (80% / 20%) ---------------------------------------

n          <- length(price_ts)
train_size <- floor(0.8 * n)

train_set <- price_ts[1:train_size]
test_set  <- price_ts[(train_size + 1):n]

cat(sprintf("\nDataset split: %d training observations | %d test observations\n",
            length(train_set), length(test_set)))

# --- 6. Stationarity Tests on Level Series -----------------------------------

cat("\n=== Stationarity Tests — Level Series ===\n")

adf_level  <- adf.test(train_set)
kpss_level <- kpss.test(train_set)
pp_level   <- pp.test(train_set)

cat(sprintf("ADF  p-value: %.4f  → %s\n",
            adf_level$p.value,
            ifelse(adf_level$p.value < 0.05, "Stationary", "Non-stationary")))

cat(sprintf("KPSS stat:    %.4f  → %s\n",
            kpss_level$statistic,
            ifelse(kpss_level$statistic > 0.463, "Non-stationary", "Stationary")))

cat(sprintf("PP   p-value: %.4f  → %s\n",
            pp_level$p.value,
            ifelse(pp_level$p.value < 0.05, "Stationary", "Non-stationary")))

# --- 7. First-Order Differencing ---------------------------------------------

train_diff <- na.omit(diff(train_set, differences = 1))
test_diff  <- na.omit(diff(test_set,  differences = 1))

cat("\n=== Stationarity Tests — Differenced Series ===\n")

adf_diff  <- adf.test(train_diff)
kpss_diff <- kpss.test(train_diff)
pp_diff   <- pp.test(train_diff)

cat(sprintf("ADF  p-value: %.4f  → %s\n",
            adf_diff$p.value,
            ifelse(adf_diff$p.value < 0.05, "Stationary ✓", "Non-stationary")))

cat(sprintf("KPSS stat:    %.4f  → %s\n",
            kpss_diff$statistic,
            ifelse(kpss_diff$statistic < 0.463, "Stationary ✓", "Non-stationary")))

cat(sprintf("PP   p-value: %.4f  → %s\n",
            pp_diff$p.value,
            ifelse(pp_diff$p.value < 0.05, "Stationary ✓", "Non-stationary")))

# --- 8. Save Processed Data --------------------------------------------------

saveRDS(list(
  price_ts   = price_ts,
  train_set  = train_set,
  test_set   = test_set,
  train_diff = train_diff,
  test_diff  = test_diff
), file = "data/processed/masi_processed.rds")

cat("\n✓ Processed data saved to data/processed/masi_processed.rds\n")
