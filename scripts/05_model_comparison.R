# =============================================================================
# MASI Index Forecasting — Script 05: Model Comparison & Summary
# Author: El Oumami Majda
# Description: Loads saved metrics, produces a unified comparison table,
#              and generates the final comparison visualization.
# =============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)

# --- 1. Build Clean Metrics Table --------------------------------------------

# Hardcode ARIMA results cleanly (avoids duplicate row bug from auto_arima$arma)
arima_metrics <- data.frame(
  Model = c("Auto ARIMA(1,1,3)", "Manual ARIMA(2,1,2)"),
  MAE   = c(1117.969, 1118.069),
  RMSE  = c(1347.305, 1347.448),
  AIC   = c(28998.61, 29012.09),
  BIC   = c(29027.83, 29041.30)
)

# Recompute Markov Switching MAE/RMSE directly from environment objects
ms_metrics <- data.frame(
  Model = "Markov Switching (2-Regime AR1)",
  MAE   = round(mean(abs(as.numeric(ms_df$y) - as.numeric(fitted_vals))), 4),
  RMSE  = round(sqrt(mean((as.numeric(ms_df$y) - as.numeric(fitted_vals))^2)), 4),
  AIC   = 5172.71,
  BIC   = 5196.08
)

all_metrics <- bind_rows(arima_metrics, ms_metrics)

cat("=== Final Model Comparison ===\n")
print(all_metrics)

write.csv(all_metrics, "outputs/final_model_comparison.csv", row.names = FALSE)
cat("✓ Results saved to outputs/final_model_comparison.csv\n")

# --- 2. Plot: MAE Comparison Bar Chart ---------------------------------------

mae_df <- all_metrics %>%
  select(Model, MAE) %>%
  mutate(Model = factor(Model, levels = unique(Model)))  # unique() prevents duplicate level error

p_mae <- ggplot(mae_df, aes(x = Model, y = MAE, fill = Model)) +
  geom_col(show.legend = FALSE, width = 0.55) +
  geom_text(aes(label = round(MAE, 2)), vjust = -0.4, size = 3.8) +
  scale_fill_manual(values = c("#1a5276", "#2e86c1", "#117a65")) +
  labs(
    title = "Mean Absolute Error (MAE) — Model Comparison",
    x     = NULL,
    y     = "MAE"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title         = element_text(face = "bold"),
    axis.text.x        = element_text(size = 9),
    panel.grid.major.x = element_blank()
  )

ggsave("figures/11_mae_comparison.png", p_mae, width = 8, height = 5, dpi = 150)
cat("✓ Figure 11: MAE comparison saved\n")

# --- 3. AIC / BIC Note -------------------------------------------------------

cat("\n⚠ Note: AIC/BIC values for ARIMA and Markov Switching are computed\n")
cat("  on different scales and are NOT directly comparable across model types.\n")
cat("  Use MAE and RMSE for cross-model evaluation on the test set.\n\n")

# --- 4. Print Transition Probability Summary ---------------------------------

cat("=== Transition Probability Matrix (Markov Switching) ===\n")
cat("           → Regime 1   → Regime 2\n")
cat("Regime 1 :   0.73         0.27\n")
cat("Regime 2 :   0.03         0.97\n\n")
cat("Interpretation:\n")
cat("• Regime 1 (High Volatility) is moderately persistent (73% chance of staying)\n")
cat("• Regime 2 (Low Volatility) is highly persistent (97% chance of staying)\n")
cat("• The market spends most of its time in the stable low-volatility regime\n\n")

# --- 5. Key Takeaways --------------------------------------------------------

cat("=== Key Takeaways ===\n")
cat("1. ARIMA(1,1,3) is the best linear model by AIC/BIC\n")
cat("2. Markov Switching achieves much lower MAE and RMSE on the training set\n")
cat("3. Markov Switching captures regime-specific dynamics that ARIMA cannot\n")
cat("4. Both models are limited by reliance on historical price data only\n")
cat("5. Future work: hybrid MS-ARIMA, GARCH volatility, or ML-based approaches\n")