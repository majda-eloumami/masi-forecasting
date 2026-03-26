# =============================================================================
# MASI Index Forecasting — Script 02: Exploratory Data Analysis
# Author: El Oumami Majda
# Description: Visualizes the MASI price series, returns distribution,
#              ACF/PACF plots, and volatility clustering.
# =============================================================================

# --- 1. Load Dependencies and Processed Data ---------------------------------

library(ggplot2)
library(xts)
library(forecast)
library(zoo)

data <- readRDS("data/processed/masi_processed.rds")

price_ts   <- data$price_ts
train_diff <- data$train_diff

price_df <- data.frame(
  Date  = index(price_ts),
  Price = as.numeric(price_ts)
)

diff_df <- data.frame(
  Date   = index(train_diff),
  Return = as.numeric(train_diff)
)

# --- 2. Plot 1: MASI Closing Price Over Time ---------------------------------

p1 <- ggplot(price_df, aes(x = Date, y = Price)) +
  geom_line(color = "#1a5276", linewidth = 0.5) +
  labs(
    title    = "MASI Index — Daily Closing Price (2012–2024)",
    subtitle = "Casablanca Stock Exchange",
    x        = NULL,
    y        = "Index Level"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold"),
    plot.subtitle = element_text(color = "gray40"),
    panel.grid.minor = element_blank()
  )

ggsave("figures/01_masi_price_series.png", p1, width = 10, height = 4.5, dpi = 150)
cat("✓ Figure 1 saved\n")

# --- 3. Plot 2: Daily Returns (First Differences) ----------------------------

p2 <- ggplot(diff_df, aes(x = Date, y = Return)) +
  geom_line(color = "#117a65", linewidth = 0.4, alpha = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  labs(
    title    = "MASI Index — Daily Returns (First Differences)",
    subtitle = "Volatility clustering visible around 2020 (COVID-19 shock)",
    x        = NULL,
    y        = "Daily Change (Points)"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold"),
    plot.subtitle = element_text(color = "gray40"),
    panel.grid.minor = element_blank()
  )

ggsave("figures/02_masi_returns.png", p2, width = 10, height = 4.5, dpi = 150)
cat("✓ Figure 2 saved\n")

# --- 4. Plot 3: Returns Distribution -----------------------------------------

p3 <- ggplot(diff_df, aes(x = Return)) +
  geom_histogram(aes(y = after_stat(density)), bins = 60,
                 fill = "#5d6d7e", color = "white", alpha = 0.8) +
  stat_function(fun = dnorm,
                args = list(mean = mean(diff_df$Return), sd = sd(diff_df$Return)),
                color = "#e74c3c", linewidth = 1) +
  labs(
    title    = "Distribution of Daily Returns",
    subtitle = "Red curve = Normal distribution overlay",
    x        = "Daily Return (Points)",
    y        = "Density"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

ggsave("figures/03_returns_distribution.png", p3, width = 7, height = 4.5, dpi = 150)
cat("✓ Figure 3 saved\n")

# --- 5. Plot 4 & 5: ACF and PACF of Differenced Series ----------------------

png("figures/04_acf_pacf_differenced.png", width = 900, height = 400, res = 100)
par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
acf(train_diff,  main = "ACF — Differenced Series",  lag.max = 35)
pacf(train_diff, main = "PACF — Differenced Series", lag.max = 35)
par(mfrow = c(1, 1))
dev.off()
cat("✓ Figure 4 saved\n")

# --- 6. Rolling Volatility (30-day) ------------------------------------------

diff_zoo <- as.zoo(train_diff)
rolling_sd <- rollapply(diff_zoo, width = 30, FUN = sd, align = "right", fill = NA)

vol_df <- data.frame(
  Date = index(rolling_sd),
  Vol  = as.numeric(rolling_sd)
) %>% na.omit()

p5 <- ggplot(vol_df, aes(x = Date, y = Vol)) +
  geom_line(color = "#884ea0", linewidth = 0.6) +
  labs(
    title    = "30-Day Rolling Volatility of MASI Returns",
    subtitle = "Peaks correspond to the 2020 COVID-19 shock and 2022 global inflation surge",
    x        = NULL,
    y        = "Rolling Std. Deviation"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold"),
    plot.subtitle = element_text(color = "gray40"),
    panel.grid.minor = element_blank()
  )

ggsave("figures/05_rolling_volatility.png", p5, width = 10, height = 4.5, dpi = 150)
cat("✓ Figure 5 saved\n")

cat("\n✓ All EDA figures saved to figures/\n")
