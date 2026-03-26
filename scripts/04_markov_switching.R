# =============================================================================
# MASI Index Forecasting — Script 04: Markov Switching Model
# Author: El Oumami Majda
# Description: Fits a 2-regime Markov Switching AR(1) model to MASI returns,
#              interprets regime-specific parameters, plots smoothed regime
#              probabilities, and compares fit with ARIMA models.
# =============================================================================

library(MSwM)
library(ggplot2)
library(xts)
library(Metrics)
library(dplyr)

# --- 1. Load Processed Data --------------------------------------------------

data <- readRDS("data/processed/masi_processed.rds")

train_diff <- data$train_diff

# --- 2. Build Input Data Frame -----------------------------------------------
# MSwM requires a standard lm() as the base model

ms_df <- data.frame(
  y    = as.numeric(train_diff),
  x_lag = dplyr::lag(as.numeric(train_diff), 1)
) %>% na.omit()

# --- 3. Fit Markov Switching Model -------------------------------------------

cat("=== Fitting Markov Switching AR(1) — 2 Regimes ===\n")
cat("(This may take a moment...)\n\n")

base_lm  <- lm(y ~ x_lag, data = ms_df)

ms_model <- msmFit(
  object = base_lm,
  k      = 2,              # Number of regimes
  sw     = rep(TRUE, 3)    # All parameters switch across regimes
)

cat("=== Model Summary ===\n")
summary(ms_model)

# --- 4. Extract Results -------------------------------------------------------

# Transition probability matrix
trans_mat <- ms_model@transMat
cat("\n=== Transition Probability Matrix ===\n")
print(round(trans_mat, 4))

# Regime-specific coefficients
coef_r1 <- ms_model@Coef[1, ]
coef_r2 <- ms_model@Coef[2, ]

cat("\n=== Regime 1 (Low Volatility) Coefficients ===\n")
print(coef_r1)

cat("\n=== Regime 2 (High Volatility) Coefficients ===\n")
print(coef_r2)

# --- 5. Compute Fitted Values -------------------------------------------------

smoothed_probs <- ms_model@Fit@smoProb

# Weighted combination of regime-specific predictions
fitted_r1 <- coef_r1[1] + coef_r1[2] * ms_df$x_lag
fitted_r2 <- coef_r2[1] + coef_r2[2] * ms_df$x_lag

fitted_vals  <- smoothed_probs[, 1] * fitted_r1 + smoothed_probs[, 2] * fitted_r2
residuals_ms <- ms_df$y - fitted_vals

# --- 6. Model Fit Metrics -----------------------------------------------------

n_obs <- nrow(ms_df)
n_par <- length(coef_r1) + length(coef_r2)
rss   <- sum(residuals_ms^2)

aic_ms   <- n_obs * log(rss / n_obs) + 2 * n_par
bic_ms   <- n_obs * log(rss / n_obs) + n_par * log(n_obs)
mae_ms   <- mean(abs(ms_df$y - fitted_vals))
rmse_ms  <- sqrt(mean((ms_df$y - fitted_vals)^2))

cat(sprintf("\n=== Markov Switching Model Fit ===\n"))
cat(sprintf("AIC : %.2f\n", aic_ms))
cat(sprintf("BIC : %.2f\n", bic_ms))
cat(sprintf("MAE : %.4f\n", mae_ms))
cat(sprintf("RMSE: %.4f\n", rmse_ms))

# Save metrics
ms_metrics <- data.frame(
  Model = "Markov Switching (2-Regime AR1)",
  AIC   = round(aic_ms, 2),
  BIC   = round(bic_ms, 2),
  MAE   = round(mae_ms, 4),
  RMSE  = round(rmse_ms, 4)
)

write.csv(ms_metrics, "outputs/markov_switching_metrics.csv", row.names = FALSE)
cat("✓ Metrics saved\n")

# --- 7. Plot: Smoothed Regime Probabilities -----------------------------------

prob_df <- data.frame(
  Index    = seq_len(nrow(smoothed_probs)),
  Regime1  = smoothed_probs[, 1],
  Regime2  = smoothed_probs[, 2]
)

prob_long <- tidyr::pivot_longer(prob_df, cols = c(Regime1, Regime2),
                                  names_to = "Regime", values_to = "Probability")

p_prob <- ggplot(prob_long, aes(x = Index, y = Probability, color = Regime)) +
  geom_line(linewidth = 0.6, alpha = 0.85) +
  scale_color_manual(
    values = c("Regime1" = "#1a5276", "Regime2" = "#c0392b"),
    labels = c("Regime 1 — Low Volatility", "Regime 2 — High Volatility")
  ) +
  labs(
    title  = "Smoothed Regime Probabilities — Markov Switching Model",
    subtitle = "High Regime 2 probability corresponds to crisis periods (e.g., COVID-19 2020)",
    x      = "Observation Index (Training Set)",
    y      = "Probability",
    color  = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold"),
    plot.subtitle = element_text(color = "gray40"),
    legend.position = "bottom"
  )

ggsave("figures/09_smoothed_regime_probabilities.png", p_prob,
       width = 10, height = 5, dpi = 150)
cat("✓ Figure 9: Smoothed regime probabilities saved\n")

# --- 8. Plot: Observed vs Fitted Values ---------------------------------------

fit_df <- data.frame(
  Index    = seq_len(n_obs),
  Observed = as.numeric(ms_df$y),
  Fitted   = as.numeric(fitted_vals)
)

p_fit <- ggplot(fit_df, aes(x = Index)) +
  geom_line(aes(y = Observed, color = "Observed"), linewidth = 0.5, alpha = 0.7) +
  geom_line(aes(y = Fitted,   color = "Fitted"),   linewidth = 0.7, linetype = "dashed") +
  scale_color_manual(values = c("Observed" = "#1a5276", "Fitted" = "#e67e22")) +
  labs(
    title  = "Observed vs Fitted — Markov Switching Model (Training Set)",
    x      = "Observation Index",
    y      = "Daily Return (Points)",
    color  = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title      = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave("figures/10_ms_observed_vs_fitted.png", p_fit,
       width = 10, height = 5, dpi = 150)
cat("✓ Figure 10: Observed vs Fitted saved\n")

cat("\n✓ Markov Switching modeling complete.\n")

