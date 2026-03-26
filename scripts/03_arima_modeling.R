# =============================================================================
# MASI Index Forecasting — Script 03: ARIMA Modeling
# Author: El Oumami Majda
# Description: Fits automated and manual ARIMA models to the MASI training
#              set, evaluates forecast accuracy, and saves diagnostic figures.
# =============================================================================
install.packages("Metrics")
library(forecast)
library(ggplot2)
library(xts)
library(Metrics)

# --- 1. Load Processed Data --------------------------------------------------

data <- readRDS("data/processed/masi_processed.rds")

train_set  <- data$train_set
test_set   <- data$test_set
train_diff <- data$train_diff
test_diff  <- data$test_diff

# --- 2. Auto ARIMA -----------------------------------------------------------

cat("=== Fitting Auto ARIMA ===\n")

auto_arima <- auto.arima(
  train_set,
  stepwise    = FALSE,   # Full grid search for best model
  approximation = FALSE,
  ic          = "aicc"
)

cat("\nSelected Model:\n")
print(auto_arima)

# --- 3. Manual ARIMA(2,1,2) --------------------------------------------------

cat("\n=== Fitting Manual ARIMA(2,1,2) ===\n")

manual_arima <- arima(train_set, order = c(2, 1, 2))
print(summary(manual_arima))

# --- 4. Forecast on Test Set -------------------------------------------------

h <- length(test_set)

auto_forecast   <- forecast(auto_arima,   h = h)
manual_forecast <- forecast(manual_arima, h = h)

# Align forecast index with test set dates
auto_fc_xts   <- xts(auto_forecast$mean,   order.by = index(test_set))
manual_fc_xts <- xts(manual_forecast$mean, order.by = index(test_set))

# --- 5. Accuracy Metrics -----------------------------------------------------

calc_metrics <- function(actual, predicted, model_name) {
  data.frame(
    Model = model_name,
    MAE   = round(mae(as.numeric(actual),  as.numeric(predicted)), 4),
    RMSE  = round(rmse(as.numeric(actual), as.numeric(predicted)), 4),
    AIC   = round(ifelse(exists("auto_arima") && model_name == "Auto ARIMA(1,1,3)",
                         AIC(auto_arima), AIC(manual_arima)), 2),
    BIC   = round(ifelse(model_name == "Auto ARIMA(1,1,3)",
                         BIC(auto_arima), BIC(manual_arima)), 2)
  )
}

metrics_auto   <- data.frame(
  Model = paste0("Auto ARIMA ", auto_arima$arma),
  MAE   = round(mae(as.numeric(test_set),  as.numeric(auto_fc_xts)), 4),
  RMSE  = round(rmse(as.numeric(test_set), as.numeric(auto_fc_xts)), 4),
  AIC   = round(AIC(auto_arima), 2),
  BIC   = round(BIC(auto_arima), 2)
)

metrics_manual <- data.frame(
  Model = "Manual ARIMA(2,1,2)",
  MAE   = round(mae(as.numeric(test_set),  as.numeric(manual_fc_xts)), 4),
  RMSE  = round(rmse(as.numeric(test_set), as.numeric(manual_fc_xts)), 4),
  AIC   = round(AIC(manual_arima), 2),
  BIC   = round(BIC(manual_arima), 2)
)

arima_results <- rbind(metrics_auto, metrics_manual)

cat("\n=== ARIMA Model Comparison ===\n")
print(arima_results)

write.csv(arima_results, "outputs/arima_model_comparison.csv", row.names = FALSE)
cat("✓ Results saved to outputs/arima_model_comparison.csv\n")

# --- 6. Residual Diagnostics — Auto ARIMA ------------------------------------

png("figures/06_arima_auto_diagnostics.png", width = 900, height = 600, res = 100)
checkresiduals(auto_arima)
dev.off()
cat("✓ Figure 6: Auto ARIMA residuals saved\n")

png("figures/07_arima_manual_diagnostics.png", width = 900, height = 600, res = 100)
checkresiduals(manual_arima)
dev.off()
cat("✓ Figure 7: Manual ARIMA residuals saved\n")

# --- 7. Forecast Plot --------------------------------------------------------

# Convert to data frame for ggplot
forecast_df <- data.frame(
  Date     = index(test_set),
  Actual   = as.numeric(test_set),
  AutoFC   = as.numeric(auto_fc_xts),
  ManualFC = as.numeric(manual_fc_xts)
)

p_fc <- ggplot(forecast_df, aes(x = Date)) +
  geom_line(aes(y = Actual,   color = "Actual"),     linewidth = 0.7) +
  geom_line(aes(y = AutoFC,   color = "Auto ARIMA"), linewidth = 0.7, linetype = "dashed") +
  geom_line(aes(y = ManualFC, color = "Manual ARIMA"), linewidth = 0.7, linetype = "dotted") +
  scale_color_manual(values = c(
    "Actual"       = "#1a5276",
    "Auto ARIMA"   = "#e74c3c",
    "Manual ARIMA" = "#27ae60"
  )) +
  labs(
    title  = "ARIMA Forecast vs Actual — Test Set",
    x      = NULL,
    y      = "MASI Index Level",
    color  = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title   = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave("figures/08_arima_forecast_vs_actual.png", p_fc, width = 10, height = 5, dpi = 150)
cat("✓ Figure 8: Forecast vs Actual saved\n")

cat("\n✓ ARIMA modeling complete.\n")
