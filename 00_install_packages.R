options(repos = c(CRAN = "https://cloud.r-project.org"))

# Prefer a user library to avoid permission/lock issues
home_dir <- Sys.getenv("USERPROFILE")
if (home_dir == "") home_dir <- Sys.getenv("HOME")
userlib <- file.path(home_dir, "Documents", "R", "library")
dir.create(userlib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(userlib, .libPaths()))

is_windows <- identical(.Platform$OS.type, "windows")

# Force binary installs on Windows (critical for old R like 4.1.x)
if (is_windows) {
  options(pkgType = "binary")
}

pkgs <- c(
  "foreign","caret","recipes","randomForest",
  "pROC","PRROC","lime","shape",
  "ggplot2","dplyr","gridExtra",
  "iml"
)

# Optional: docs tooling. Not required for the pipeline.
if (Sys.getenv("INSTALL_DOCS") == "1") {
  pkgs <- c(pkgs, "knitr", "rmarkdown")
}

installed <- rownames(installed.packages())
need <- setdiff(pkgs, installed)

if (length(need) > 0) {
  message("Installing packages: ", paste(need, collapse = ", "))
  install.packages(need, dependencies = TRUE, type = if (is_windows) "binary" else getOption("pkgType"))
}

missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing) > 0) {
  stop("Missing packages after install: ", paste(missing, collapse = ", "))
}

cat("✅ All required packages installed (runtime only).\n")
cat("ℹ️ To install knitr/rmarkdown, run with INSTALL_DOCS=1 environment variable.\n")
