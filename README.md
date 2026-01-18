Mammography Dataset – Interpretable Machine Learning with LIME and Fidelity Analysis
📖 Project Overview

This project investigates local explainability and explanation fidelity for a vanilla Random Forest classifier trained on the Mammography dataset (OpenML).

The primary objective is not to optimize predictive performance, but to systematically evaluate how well post-hoc explanations (LIME) approximate the underlying black-box model locally, and to quantify this approximation via fidelity (explanation fit).

The project is designed with doctoral-level reproducibility and interpretability standards, emphasizing:

Transparent modeling

Explicit separation of training, explanation, and evaluation stages

Quantitative assessment of explanation reliability

🎯 Research Objectives

Train a baseline Random Forest model on an imbalanced medical dataset.

Generate LIME explanations for individual observations.

Quantify explanation fidelity using local surrogate model R^2.

Analyze the distribution of fidelity across observations.

Assess which features consistently dominate local explanations.

Discuss interpretability limitations in highly imbalanced clinical settings.

🗂 Dataset Description

Dataset: Mammography

Source: OpenML

Observations: 11,183

Features: 6 numeric attributes (attr1–attr6)

Target: Binary classification (negatif, pozitif)

Class imbalance: ~2.3% positive class

This imbalance motivates the use of PR curves and explanation analysis, beyond standard ROC-based evaluation.

⚙️ Modeling Pipeline
1️⃣ Data Preparation

Stratified train/test split

No feature engineering or resampling applied

Goal: preserve raw data structure for interpretability

2️⃣ Model Training

Algorithm: Random Forest

No hyperparameter tuning (intentional)

Purpose: isolate explanation behavior from model optimization

3️⃣ Model Evaluation

ROC curve

Precision–Recall curve

Metrics saved in metrics_rf.csv

🔍 Explainability Framework
LIME (Local Interpretable Model-Agnostic Explanations)

For each selected observation:

A local linear surrogate model is fitted

Feature contributions are estimated locally

The surrogate’s R^2 is recorded as fidelity

Important:
Fidelity measures how well the explanation approximates the model,
not whether the explanation is “true” in a causal sense.

📊 Fidelity Analysis
Fidelity Distribution

Mean fidelity ≈ 0.64

Distribution spans approximately 0.4 – 0.8

This indicates:

LIME explanations are moderately reliable on average

Some observations exhibit weak local approximations

Explanations should therefore be interpreted conditionally

Interpretation Guideline
Fidelity Range	Interpretation
< 0.5	Weak explanation – high uncertainty
0.5 – 0.7	Moderate local approximation
> 0.7	Strong local fit
📈 Feature-Level Insights
LIME Feature Effects

Aggregating local explanations reveals that:

attr4, attr5, and attr6 consistently dominate local decision logic

Feature effects exhibit non-linear and threshold-like behavior

These patterns suggest that the Random Forest relies on piecewise decision regions, rather than smooth monotonic relationships.

⚠️ Methodological Limitations

LIME explanations are locally valid only

Fidelity varies substantially across observations

Correlated features may distort local linear approximations

No causal interpretation is implied

This project intentionally avoids overstating interpretability claims.

▶️ Reproducibility
Run the full pipeline:
source("scripts/run_all.R")


All outputs are generated under the outputs/ directory.

📌 Academic Positioning

This project aligns with:

Interpretable ML literature (LIME, local surrogates)

Medical ML best practices (PR curves, imbalance awareness)

Doctoral-level standards for explanation validation, not just visualization

🧠 Key Takeaway

Interpretability without fidelity assessment is storytelling.
This project treats explanations as models that must themselves be evaluated.
