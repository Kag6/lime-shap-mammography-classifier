# scripts/01_load_and_split.R
# Load Mammography (OpenML) ARFF and create stratified train/test split

suppressPackageStartupMessages({
  library(foreign)
  library(caret)
  library(dplyr)
})

cat("\n====================================\n")
cat("Veri Yükleme ve Bölme\n")
cat("====================================\n\n")

if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)

data_path <- "data/mammography.arff"
if (!file.exists(data_path)) {
  stop("❌ ARFF dosyası bulunamadı: ", data_path,
       "\nLütfen 'data/mammography.arff' dosyasını ekleyin.")
}

cat("Veri yükleniyor: ", data_path, "\n", sep = "")
mammography <- read.arff(data_path)

# Ensure 'class' exists and map {-1,1} -> {negatif, pozitif}
if (!"class" %in% names(mammography)) {
  stop("❌ 'class' kolonu bulunamadı. Kolonlar: ", paste(names(mammography), collapse = ", "))
}

# Some ARFF readers may bring class as factor/character/numeric
# Coerce to character first to robustly map
mammography$class <- as.character(mammography$class)

# Normalize possible encodings
mammography$class[mammography$class %in% c("-1", "negatif", "negative", "0")] <- "-1"
mammography$class[mammography$class %in% c("1", "pozitif", "positive", "1.0")] <- "1"

mammography$class <- factor(mammography$class, levels = c("-1", "1"), labels = c("negatif", "pozitif"))

cat("✅ Veri yüklendi: ", nrow(mammography), " gözlem, ", ncol(mammography), " değişken\n", sep = "")
cat("\nSınıf dağılımı:\n")
print(table(mammography$class))

set.seed(42)
idx <- createDataPartition(mammography$class, p = 0.8, list = FALSE)
train_data <- mammography[idx, ]
test_data  <- mammography[-idx, ]

cat("\n✅ Train set: ", nrow(train_data), " gözlem\n", sep = "")
cat("✅ Test set: ", nrow(test_data), " gözlem\n", sep = "")

cat("\nTrain sınıf dağılımı:\n")
print(table(train_data$class))
cat("\nTest sınıf dağılımı:\n")
print(table(test_data$class))

# Save both legacy .RData (compat) and strict .rds (reproducible)
save(train_data, test_data, file = "outputs/data_split.RData")
saveRDS(list(train_data = train_data, test_data = test_data), "outputs/data_split.rds")

cat("\n✅ Veri 'outputs/data_split.RData' ve 'outputs/data_split.rds' dosyalarına kaydedildi.\n")
cat("====================================\n")
