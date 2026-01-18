# scripts/03_lime_batch.R
# Batch LIME explanations + save

suppressPackageStartupMessages({
  library(lime)
  library(dplyr)
  library(randomForest)
})

cat("\n====================================\n")
cat("LIME Batch Açıklamaları\n")
cat("====================================\n\n")

if (!file.exists("outputs/data_split.RData")) stop("❌ outputs/data_split.RData yok. Önce 01 çalıştır.")
if (!file.exists("outputs/rf_model.rds")) stop("❌ outputs/rf_model.rds yok. Önce 02 çalıştır.")

load("outputs/data_split.RData")
rf_model <- readRDS("outputs/rf_model.rds")

# LIME hooks for randomForest
model_type.randomForest <- function(x, ...) "classification"
predict_model.randomForest <- function(x, newdata, type, ...) {
  p <- predict(x, newdata, type = "prob")
  data.frame(pozitif = p[, "pozitif"], negatif = p[, "negatif"])
}

train_x <- train_data %>% select(-class)
explainer <- lime(train_x, rf_model, bin_continuous = TRUE, n_bins = 5)

# balanced-ish sample: all positives + 3x negatives
pos_idx <- which(test_data$class == "pozitif")
neg_all <- which(test_data$class == "negatif")

set.seed(42)
neg_n <- min(length(neg_all), max(1, length(pos_idx) * 3))
neg_idx <- sample(neg_all, size = neg_n)

cand_idx <- c(pos_idx, neg_idx)
new_obs_x <- test_data[cand_idx, ] %>% select(-class)

cat("ℹ️  LIME: ", nrow(new_obs_x), " gözlem (pozitif=", length(pos_idx), ", negatif=", length(neg_idx), ")\n", sep = "")

lime_exp <- lime::explain(
  x = new_obs_x,
  explainer = explainer,
  n_labels = 1,
  n_features = 6,
  kernel_width = 0.75
)

# attach original row ids for traceability
lime_exp$case <- cand_idx[lime_exp$case]

saveRDS(lime_exp, "outputs/lime_explanations.rds")

cat("✅ outputs/lime_explanations.rds yazıldı.\n")
