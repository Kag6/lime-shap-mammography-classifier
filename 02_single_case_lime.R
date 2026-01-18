# scripts/03_single_case_lime.R
# Tekil hasta örnekleri için LIME açıklamaları

suppressPackageStartupMessages({
  library(lime)
  library(dplyr)
  library(ggplot2)
  library(randomForest)
})

cat("\n====================================\n")
cat("Tekil Hasta LIME Açıklamaları\n")
cat("====================================\n\n")

# Veri ve model kontrol
if (!file.exists("outputs/data_split.RData") || !file.exists("outputs/rf_model.rds")) {
  stop("❌ Önce 02_rf_lime_pipeline.R scriptini çalıştırın!")
}

load("outputs/data_split.RData")
rf_model <- readRDS("outputs/rf_model.rds")

# LIME metodları
model_type.randomForest <- function(x, ...) "classification"
predict_model.randomForest <- function(x, newdata, type, ...) {
  p <- predict(x, newdata, type = "prob")
  data.frame(pozitif = p[, "pozitif"], negatif = p[, "negatif"])
}

# Explainer
train_x <- select(train_data, -class)
explainer <- lime(
  x = train_x,
  model = rf_model,
  bin_continuous = TRUE,
  n_bins = 5
)

# Çıktı klasörü
if (!dir.exists("outputs/lime_single")) {
  dir.create("outputs/lime_single", recursive = TRUE)
}

# Hasta indeksleri
cases <- c(75, 175)

for (cid in cases) {
  if (cid > nrow(test_data)) {
    cat("⚠️  Hasta", cid, "test setinde yok, atlanıyor...\n")
    next
  }
  
  case_obs <- test_data[cid, ]
  case_x <- select(case_obs, -class)
  
  cat("\n🔍 Hasta", cid, "analizi:\n")
  cat("   Gerçek sınıf:", as.character(case_obs$class), "\n")
  
  # Model tahmini
  pred_prob <- predict(rf_model, case_x, type = "prob")
  cat("   Pozitif olasılığı:", round(pred_prob[, "pozitif"], 3), "\n")
  
  # LIME açıklaması
  lime_case <- explain(
    x = case_x,
    explainer = explainer,
    n_labels = 1,
    n_features = 6
  )
  
  cat("\n   LIME Açıklaması:\n")
  print(select(lime_case, feature, feature_value, feature_weight, 
               model_prediction, model_r2))
  
  # Grafik
  p <- plot_features(lime_case, ncol = 1)
  
  out_path <- file.path("outputs", "lime_single",
                        paste0("lime_case_", cid, ".png"))
  ggsave(out_path, plot = p, width = 10, height = 6)
  cat("\n   ✅ Grafik kaydedildi:", out_path, "\n")
}

cat("\n====================================\n")
cat("✅ Tekil hasta analizleri tamamlandı\n")
cat("====================================\n")