## Readme on Feature Selection Process, Feature Analysis (Scripts and Results)

### 1) Feature extraction:
The scripts to extract the features can be found in `extract_features_elfen.py` and `extract_features_lftk.py`. 

### 2) Robust feature selection process:
The script `feature_selection_robust.py` performs the robust feature selection process. 
It uses elastic net regression with stability selection to select the most important features. The process is as follows:

As a first step, we apply a filtering method to select a meaningful set of features as predictors: We keep only features with variance > 0 and perform a correlation analysis, retaining features with correlation < 0.7 and selecting one representative feature per highly correlated group. This yields 145 initial features.
The correlation dendogram can be found in `results_feature_selection/plots/dendrogram_correlation_features.png`.
The script `feature_analysis_elastic_net` is used to perform stability selection using logistic regression with elastic net regularization on a balanced subset of 200k paragraphs from the *original* corpus, applying 5-fold inner and 10-fold outer cross-validation to assess robustness. 
The resulting table with the feature selection results can be found in `results_feature_selection/robust_results_feature_summary.csv`. This table contains information on the selection frequency, effect direction, odds, and approximate sign for each of the originally selected 145 features.

The model results (with pseud R^2 and AUC) can be found in `nested_cv_summary.csv` and `per_fold_results.csv`.

### 3) Final feature selection:
For our final selection we remove all features that (a) are not selected in all folds (a feature is selected when coefficient > 0), (b) showed inconsistent effects, (c) show less than ±5\% change in odds and (d) were not significant (we bootstrapped CIs to approximate sign.).
This leaves 43 robust features. The script to apply this heuristic is `feature_selection_final.py`. The resulting table with the final features can be found in `results_feature_selection/reliable_features_odds_with_feature_groups.csv`. This table contains information on the selection frequency, effect direction, odds, approximate sign and feature group for each of the 43 final features.

### 4) Unbiased estimates:
To further reduce the number, we rank them by absolute change in odds and select the top features per feature group, resulting in 24 final features.
The R script to run the regression analysis to get unbiased estimates on these 24 features for the *original* dataset is `regression_realistic.R`
The R script to run the regression analysis to get unbiased estimates on these 24 features for the *synthetic* dataset is `regression_synthetic.R`. The resulting tables with the unbiased estimates can be found in `results_feature_selection/odds_realistic.csv` and `results_feature_selection/odds_synthetic.csv`.
The corresponding plots can be found in `results_feature_analysis/plots/forest_plot_reliable_features_group1.png` and `results_feature_analysis/plots/forest_plot_reliable_features_group2.png`.


