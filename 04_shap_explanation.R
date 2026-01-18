# scripts/04_shap_explanation.R
# SHAP-benzeri açıklamalar (iml paketi ile)

suppressPackageStartupMessages({
  library(iml)
  library(randomForest)
  library(dplyr)
})

cat("\n====================================\n")
cat("SHAP-like Açıklamalar (iml)\n")
cat("====================================\n\n")

# Veri ve model kontrol
if (!file.exists("outputs/data_split.RData") || !file.exists("outputs/rf_model.rds")) {
  stop("❌ Önce 02_rf_lime_pipeline.R scriptini çalıştırın!")
}

load("outputs/data_split.RData")
rf_model <- readRDS("outputs/rf_model.rds")

cat("✅ Model ve veri yüklendi\n")

# Predictor oluştur
cat("\n🔧 IML Predictor oluşturuluyor...\n")
predictor <- Predictor$new(
  model = rf_model,
  data = select(train_data, -class),
  y = train_data$class,
  type = "prob"
)

# Shapley değerleri (tek bir gözlem için)
cat("\n🔍 Shapley değerleri hesaplanıyor (Hasta 15)...\n")
if (nrow(test_data) >= 15) {
  sh <- Shapley$new(
    predictor = predictor,
    x.interest = select(test_data[15, ], -class),
    sample.size = 100
  )
  
  png("outputs/shap_case15.png", width = 800, height = 500)
  plot(sh)
  dev.off()
  
  cat("✅ Shapley grafiği: outputs/shap_case15.png\n")
} else {
  cat("⚠️  Test setinde 15. gözlem yok\n")
}

# Global Feature Importance
cat("\n📊 Global feature importance hesaplanıyor...\n")
feat_imp <- FeatureImp$new(
  predictor = predictor,
  loss = "ce",
  n.repetitions = 10
)

png("outputs/shap_global.png", width = 800, height = 500)
plot(feat_imp)
dev.off()

cat("✅ Global importance grafiği: outputs/shap_global.png\n")

# Feature effects (ALE plot)
cat("\n📈 ALE (Accumulated Local Effects) hesaplanıyor...\n")
# İlk özellik için ALE
first_feature <- colnames(select(train_data, -class))[1]
ale <- FeatureEffect$new(
  predictor = predictor,
  feature = first_feature,
  method = "ale"
)

png("outputs/ale_first_feature.png", width = 800, height = 500)
plot(ale)
dev.off()

cat("✅ ALE grafiği:", first_feature, "-> outputs/ale_first_feature.png\n")

cat("\n====================================\n")
cat("✅ SHAP-like analizler tamamlandı\n")
cat("====================================\n")