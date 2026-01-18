# scripts/02_rf_lime_pipeline.R
# Random Forest + LIME pipeline

suppressPackageStartupMessages({
  library(randomForest)
  library(dplyr)
  library(ggplot2)
  library(pROC)
  library(PRROC)
  library(caret)
  library(lime)
  library(gridExtra)
})

cat("\n====================================\n")
cat("Random Forest + LIME Pipeline\n")
cat("====================================\n\n")

# Veriyi yükle
if (!file.exists("outputs/data_split.RData")) {
  stop("❌ Önce 01_load_and_split.R scriptini çalıştırın!")
}

load("outputs/data_split.RData")
cat("✅ Veri yüklendi\n")

# Random Forest modeli
cat("\n🌲 Random Forest modeli eğitiliyor...\n")
set.seed(42)
rf_model <- randomForest(class ~ ., data = train_data, ntree = 500)
saveRDS(rf_model, "outputs/rf_model.rds")
print(rf_model)

# Test tahminleri
cat("\n📊 Test seti değerlendiriliyor...\n")
test_prob <- predict(rf_model, newdata = test_data, type = "prob")[, "pozitif"]
test_pred_label <- factor(
  ifelse(test_prob > 0.5, "pozitif", "negatif"),
  levels = c("negatif", "pozitif")
)

# Confusion Matrix
cm <- confusionMatrix(
  data = test_pred_label,
  reference = test_data$class,
  positive = "pozitif"
)

# ROC Curve
roc_obj <- roc(
  response = test_data$class,
  predictor = test_prob,
  levels = c("negatif", "pozitif"),
  direction = "<"
)
auc_val <- auc(roc_obj)

png("outputs/roc_curve.png", width = 600, height = 600)
plot(roc_obj, main = paste0("ROC Curve (AUC = ", round(as.numeric(auc_val), 3), ")"))
abline(a = 0, b = 1, lty = 2, col = "gray")
dev.off()

# PR Curve
y_true <- ifelse(test_data$class == "pozitif", 1, 0)
pr_obj <- pr.curve(
  scores.class0 = test_prob,
  weights.class0 = y_true,
  curve = TRUE
)

png("outputs/pr_curve.png", width = 600, height = 600)
plot(pr_obj)
dev.off()

# Metrikleri kaydet
metrics <- data.frame(
  Metric = c("Accuracy", "Sensitivity", "Specificity",
             "Precision", "F1", "ROC_AUC", "PR_AUC"),
  Value = c(
    cm$overall["Accuracy"],
    cm$byClass["Sensitivity"],
    cm$byClass["Specificity"],
    cm$byClass["Precision"],
    cm$byClass["F1"],
    as.numeric(auc_val),
    pr_obj$auc.integral
  ),
  stringsAsFactors = FALSE
)
rownames(metrics) <- NULL

write.csv(metrics, "outputs/metrics_rf.csv", row.names = FALSE)

cat("\n📊 Test Metrikleri:\n")
print(metrics, row.names = FALSE)

# LIME açıklamaları
cat("\n🔍 LIME açıklamaları üretiliyor...\n")

# RandomForest için LIME metodları
model_type.randomForest <- function(x, ...) "classification"
predict_model.randomForest <- function(x, newdata, type, ...) {
  p <- predict(x, newdata, type = "prob")
  data.frame(pozitif = p[, "pozitif"], negatif = p[, "negatif"])
}

# Explainer oluştur
train_x <- select(train_data, -class)
explainer <- lime(
  x = train_x,
  model = rf_model,
  bin_continuous = TRUE,
  n_bins = 5
)

# Açıklanacak gözlemleri seç
pos_idx <- which(test_data$class == "pozitif")
neg_idx_all <- which(test_data$class == "negatif")

set.seed(42)
neg_sample_size <- min(length(neg_idx_all), length(pos_idx) * 3)
neg_idx <- sample(neg_idx_all, size = neg_sample_size)

cand_idx <- c(pos_idx, neg_idx)
new_obs_x <- select(test_data[cand_idx, ], -class)

cat("ℹ️  Toplam", nrow(new_obs_x), "gözlem için LIME açıklaması üretiliyor\n")
cat("   - Pozitif:", length(pos_idx), "gözlem\n")
cat("   - Negatif:", length(neg_idx), "gözlem\n")

# LIME açıklamalarını üret
lime_exp <- explain(
  x = new_obs_x,
  explainer = explainer,
  n_labels = 1,
  n_features = 5,
  kernel_width = 0.75
)

saveRDS(lime_exp, "outputs/lime_explanations.rds")

# Fidelity analizi
lime_exp_clean <- lime_exp %>%
  filter(!is.na(model_r2)) %>%
  mutate(model_r2 = pmin(model_r2, 1))

cat("\n📊 Fidelity (model_r2) Özeti:\n")
print(summary(lime_exp_clean$model_r2))

# Fidelity grafikleri
p_hist <- ggplot(lime_exp_clean, aes(x = model_r2)) +
  geom_histogram(bins = 30, fill = "steelblue", color = "white", alpha = 0.8) +
  geom_vline(aes(xintercept = mean(model_r2)),
             color = "red", linetype = "dashed", linewidth = 1) +
  labs(
    title = "LIME Fidelity Histogram",
    x = "Fidelity (model_r2)",
    y = "Frekans"
  ) +
  theme_minimal(base_size = 14)

p_dens <- ggplot(lime_exp_clean, aes(x = model_r2)) +
  geom_density(fill = "skyblue", alpha = 0.6) +
  geom_vline(aes(xintercept = mean(model_r2)),
             color = "red", linetype = "dashed", linewidth = 1) +
  annotate("text",
           x = mean(lime_exp_clean$model_r2),
           y = max(density(lime_exp_clean$model_r2)$y) * 0.9,
           label = paste("Mean =", round(mean(lime_exp_clean$model_r2), 3)),
           hjust = -0.1, vjust = 0, size = 4, color = "red") +
  labs(
    title = "LIME Fidelity Density",
    x = "Fidelity (model_r2)",
    y = "Yoğunluk"
  ) +
  theme_minimal(base_size = 14)

png("outputs/fidelity_hist_density.png", width = 1200, height = 700)
grid.arrange(p_hist, p_dens, ncol = 2)
dev.off()

# Feature effects
feature_effects <- lime_exp %>%
  group_by(feature) %>%
  summarise(
    mean_effect = mean(feature_weight, na.rm = TRUE),
    sd_effect = sd(feature_weight, na.rm = TRUE),
    direction = ifelse(mean_effect > 0, "Pozitif", "Negatif"),
    .groups = "drop"
  ) %>%
  arrange(desc(abs(mean_effect)))

cat("\n📊 Feature Effects:\n")
print(feature_effects, n = 20)

p_feat <- ggplot(feature_effects,
                 aes(x = reorder(feature, mean_effect),
                     y = mean_effect,
                     fill = direction)) +
  geom_col(alpha = 0.85) +
  coord_flip() +
  labs(
    title = "LIME Feature Effects (Average Influence)",
    x = "Feature",
    y = "Average Effect (Feature Weight)"
  ) +
  scale_fill_manual(values = c("Pozitif" = "firebrick", "Negatif" = "steelblue")) +
  theme_minimal(base_size = 14)

png("outputs/lime_feature_effects.png", width = 1000, height = 600)
print(p_feat)
dev.off()

cat("\n====================================\n")
cat("✅ Pipeline tamamlandı!\n")
cat("Çıktılar 'outputs/' klasöründe\n")
cat("====================================\n")