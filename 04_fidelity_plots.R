# scripts/04_fidelity_plots.R
# Fidelity distribution plots (hist + density) -> outputs/fidelity_distribution.png

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(gridExtra)
})

cat("\n====================================\n")
cat("Fidelity Dağılımı\n")
cat("====================================\n\n")

if (!file.exists("outputs/lime_explanations.rds")) stop("❌ outputs/lime_explanations.rds yok. Önce 03 çalıştır.")

lime_exp <- readRDS("outputs/lime_explanations.rds") %>%
  filter(!is.na(model_r2)) %>%
  mutate(model_r2 = pmin(pmax(model_r2, 0), 1))

if (nrow(lime_exp) == 0) stop("❌ model_r2 boş. LIME açıklamalarını kontrol et.")

m <- mean(lime_exp$model_r2)

p_hist <- ggplot(lime_exp, aes(x = model_r2)) +
  geom_histogram(bins = 30, alpha = 0.85) +
  geom_vline(xintercept = m, linetype = "dashed", linewidth = 0.9) +
  labs(title = "LIME Fidelity Histogram", x = "Fidelity (model_r2)", y = "Count") +
  theme_minimal(base_size = 13)

p_den <- ggplot(lime_exp, aes(x = model_r2)) +
  geom_density(alpha = 0.6) +
  geom_vline(xintercept = m, linetype = "dashed", linewidth = 0.9) +
  labs(title = "LIME Fidelity Density", x = "Fidelity (model_r2)", y = "Density") +
  theme_minimal(base_size = 13)

png("outputs/fidelity_distribution.png", width = 1200, height = 700)
grid.arrange(p_hist, p_den, ncol = 2)
dev.off()

cat("✅ outputs/fidelity_distribution.png yazıldı. Mean=", round(m, 3), "\n", sep = "")
