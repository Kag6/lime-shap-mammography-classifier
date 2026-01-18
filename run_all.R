########################################
#  Mammography ML Pipeline - Run All   #
########################################

# IMPORTANT: Run from project root
# In VS Code: Rscript -e "source('run_all.R')"

source("scripts/00_install_packages.R")

scripts <- c(
  "scripts/01_load_and_split.R",
  "scripts/02_train_and_evaluate_rf.R",
  "scripts/03_lime_batch.R",
  "scripts/04_fidelity_plots.R",
  "scripts/05_lime_feature_effects.R",
  "scripts/06_lime_case_examples.R",
  "scripts/07_shap_explanation.R",
  "scripts/08_advanced_fidelity_viz.R",
  "scripts/09_calibration_plots.R"
)

# UTF-8 output (fixes weird console glyphs in Windows)
try(Sys.setlocale("LC_CTYPE", "Turkish_Turkey.1254"), silent = TRUE)
try(Sys.setlocale("LC_CTYPE", "en_US.UTF-8"), silent = TRUE)

for (i in seq_along(scripts)) {
  s <- scripts[[i]]
  cat("\n==================================================\n")
  cat(sprintf("STEP %d of %d : %s\n", i, length(scripts), s))
  cat("==================================================\n\n")

  tryCatch({
    source(s)
    cat("\n✅ BAŞARILI:", s, "\n")
  }, error = function(e) {
    cat("\n❌ HATA:", s, "\n")
    cat("Hata mesajı:", conditionMessage(e), "\n")
    stop("Pipeline durdu. Lütfen hatayı düzeltin.")
  })
}

# Hard output checks (pipeline must not pass silently)
required <- c(
  "outputs/metrics_rf.csv",
  "outputs/roc_curve.png",
  "outputs/pr_curve.png",
  "outputs/fidelity_distribution.png",
  "outputs/lime_explanations.rds",
  "outputs/lime_feature_effects.png",
  "outputs/calibration.png",
  "outputs/shap_outputs/permutation_importance.csv",
  "outputs/shap_outputs/permutation_importance_bar.png",
  "outputs/shap_outputs/shap_case_15.png"
)

missing <- required[!file.exists(required)]
if (length(missing) > 0) {
  cat("\n❌ Eksik çıktılar bulundu:\n")
  print(missing)
  stop("Eksik çıktı var. Pipeline başarısız sayıldı.")
}

cat("\n✅ PIPELINE COMPLETED. Check outputs/ folder.\n")
