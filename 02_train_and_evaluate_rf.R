# scripts/02_train_and_evaluate_rf.R
# Train vanilla Random Forest and compute ROC/PR + metrics + calibration assets

suppressPackageStartupMessages({
  library(randomForest)
  library(pROC)
  library(PRROC)
  library(caret)
})

cat("\n====================================\n")
cat("Random Forest Eğitimi ve Değerlendirme\n")
cat("====================================\n\n")

if (!file.exists("outputs/data_split.RData")) {
  stop("❌ outputs/data_split.RData yok. Önce scripts/01_load_and_split.R çalıştır.")
}

load("outputs/data_split.RData")

set.seed(42)
rf_model <- randomForest(class ~ ., data = train_data, ntree = 500)
saveRDS(rf_model, "outputs/rf_model.rds")

# Predict probabilities
prob_mat <- predict(rf_model, newdata = test_data, type = "prob")
if (!"pozitif" %in% colnames(prob_mat)) {
  stop("❌ Beklenen olasılık kolonu bulunamadı. Olasılık kolonları: ", paste(colnames(prob_mat), collapse = ", "))
}

test_prob <- prob_mat[, "pozitif"]

test_pred <- factor(ifelse(test_prob > 0.5, "pozitif", "negatif"), levels = c("negatif", "pozitif"))

# Confusion matrix
cm <- confusionMatrix(test_pred, test_data$class, positive = "pozitif")

# ROC
roc_obj <- roc(test_data$class, test_prob, levels = c("negatif", "pozitif"), direction = "<")
auc_val <- as.numeric(auc(roc_obj))

png("outputs/roc_curve.png", width = 700, height = 700)
plot(roc_obj, main = sprintf("ROC Curve (AUC = %.3f)", auc_val))
abline(a = 0, b = 1, lty = 2, col = "gray")
dev.off()

# PR (note: PRROC expects scores for class0; here we treat positive as class0 via weights)
y_true <- ifelse(test_data$class == "pozitif", 1, 0)
pr_obj <- pr.curve(scores.class0 = test_prob, weights.class0 = y_true, curve = TRUE)

png("outputs/pr_curve.png", width = 700, height = 700)
plot(pr_obj)
dev.off()

metrics <- data.frame(
  Metric = c("Accuracy","Sensitivity","Specificity","Precision","F1","ROC_AUC","PR_AUC"),
  Value = c(
    unname(cm$overall["Accuracy"]),
    unname(cm$byClass["Sensitivity"]),
    unname(cm$byClass["Specificity"]),
    unname(cm$byClass["Precision"]),
    unname(cm$byClass["F1"]),
    auc_val,
    pr_obj$auc.integral
  )
)
write.csv(metrics, "outputs/metrics_rf.csv", row.names = FALSE)

# Save evaluation assets for downstream plots (calibration, risk-fidelity)
saveRDS(
  list(test_prob = test_prob, y_true = y_true, test_label = test_data$class),
  "outputs/predictions_test.rds"
)

cat("✅ Model ve metrikler outputs/ klasörüne yazıldı.\n")
