# scripts/05_lime_feature_effects.R
# Aggregate LIME feature effects (mean +/- 1 SD) -> outputs/lime_feature_effects.png

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
})

cat("\n====================================\n")
cat("LIME Feature Effects\n")
cat("====================================\n\n")

if (!file.exists("outputs/lime_explanations.rds")) stop("❌ outputs/lime_explanations.rds yok. Önce 03 çalıştır.")

lime_exp <- readRDS("outputs/lime_explanations.rds")

feat <- lime_exp %>%
  group_by(feature) %>%
  summarise(
    mean_effect = mean(feature_weight, na.rm = TRUE),
    sd_effect = sd(feature_weight, na.rm = TRUE),
    n = sum(!is.na(feature_weight)),
    .groups = "drop"
  ) %>%
  mutate(abs_mean = abs(mean_effect)) %>%
  arrange(desc(abs_mean))

write.csv(feat, "outputs/lime_feature_effects.csv", row.names = FALSE)

p <- ggplot(feat, aes(x = reorder(feature, mean_effect), y = mean_effect)) +
  geom_col(alpha = 0.9) +
  geom_errorbar(aes(ymin = mean_effect - sd_effect, ymax = mean_effect + sd_effect), width = 0.2, alpha = 0.7) +
  coord_flip() +
  labs(
    title = "LIME Feature Effects (Mean ± 1 SD)",
    x = "Feature",
    y = "Mean local contribution (feature_weight)"
  ) +
  theme_minimal(base_size = 13)

png("outputs/lime_feature_effects.png", width = 1100, height = 700)
print(p)
dev.off()

cat("✅ outputs/lime_feature_effects.png ve .csv yazıldı.\n")
