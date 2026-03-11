import argparse

import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score, accuracy_score, confusion_matrix, classification_report
import joblib
import seaborn as sns
import json


def get_clean_feature_df(feature_df, features):
    """
    Clean and preprocess the dataframe:
    - Drop text columns and IDs if present
    - Remove columns with arrays/lists
    - Remove columns with all NaNs or one unique value
    - Replace inf values, fill NaNs (numeric -> mean, bool/int -> 0)
    """
    # 1. Drop clearly irrelevant columns
    columns_to_ignore = {"abstract", "full_text", "title", "text", "acl_id", "after"}
    df = feature_df.drop(columns=columns_to_ignore.intersection(feature_df.columns), errors="ignore")
    # only keep features that are in the provided features list
    df = df[[col for col in df.columns if col in features]]

    # 2. Remove columns containing lists/arrays in any row
    def is_array_column(series):
        return series.apply(lambda x: isinstance(x, (list, np.ndarray))).any()

    array_cols = [col for col in df.columns if is_array_column(df[col])]
    df = df.drop(columns=array_cols, errors="ignore")

    # 3. Drop columns with only NaNs or a single unique value
    drop_cols = [col for col in df.columns if df[col].isnull().all() or df[col].nunique() <= 1]
    df = df.drop(columns=drop_cols, errors="ignore")
    print(f"Dropped {len(array_cols) + len(drop_cols)} columns (arrays/NaNs/constants). Remaining shape: {df.shape}")

    # 4. Replace inf/-inf with NaN
    df.replace([np.inf, -np.inf], np.nan, inplace=True)
    # how many NaNs are in the dataframe now?
    print(f"Dataframe shape after cleaning: {df.shape}. Total NaNs: {df.isna().sum().sum()}")

    # 5. Fill remaining NaNs: numeric -> mean, others -> 0
    for col in df.columns:
        if pd.api.types.is_numeric_dtype(df[col]):
            df[col].fillna(df[col].mean(), inplace=True)
        else:
            df[col].fillna(0, inplace=True)

    # 6. Final safety check
    df.fillna(0, inplace=True)

    return df


def pseudo_r2_measures(y_true, y_pred_proba):
    """
    Compute McFadden and Nagelkerke pseudo-R² for logistic regression.
    """
    eps = 1e-15
    y_pred_proba = np.clip(y_pred_proba, eps, 1 - eps)

    ll_full = np.sum(y_true * np.log(y_pred_proba) + (1 - y_true) * np.log(1 - y_pred_proba))
    p_mean = np.mean(y_true)
    ll_null = np.sum(y_true * np.log(p_mean) + (1 - y_true) * np.log(1 - p_mean))

    r2_mcfadden = 1 - (ll_full / ll_null)
    n = len(y_true)
    r2_nagelkerke = r2_mcfadden / (1 - (ll_null / n))

    return r2_mcfadden, r2_nagelkerke


def fit_final_logistic_regression_unpenalized(
        X_full, y_full, selected_features, SEED=42,
        coef_file="final_model_coefficients.csv",
        metrics_file="final_model_metrics.json",
        model_file="final_logistic_model.pkl"
):
    """
    Fit an unpenalized logistic regression on the full dataset using selected features.
    Compute AUC and pseudo-R², and save results to disk.
    """

    # Subset selected features
    X_sel = X_full[selected_features].copy()

    # Define pipeline
    pipeline = Pipeline([
        ('scaler', StandardScaler()),
        ('logreg', LogisticRegression(
            penalty=None,  # no regularization
            solver='lbfgs',
            max_iter=2000,
            random_state=SEED
        ))
    ])

    # Fit model
    pipeline.fit(X_sel, y_full)

    # Predictions for performance metrics
    y_pred = pipeline.predict(X_sel)
    y_pred_proba = pipeline.predict_proba(X_sel)[:, 1]

    # Compute metrics
    auc = roc_auc_score(y_full, y_pred_proba)
    acc = accuracy_score(y_full, y_pred)
    conf = confusion_matrix(y_full, y_pred)
    report = classification_report(y_full, y_pred, digits=3)
    r2_mcf, r2_nag = pseudo_r2_measures(y_full, y_pred_proba)

    metrics = {
        "AUC": round(auc, 4),
        "Accuracy": round(acc, 4),
        "McFadden_R2": round(r2_mcf, 4),
        "Nagelkerke_R2": round(r2_nag, 4),
        "Confusion_Matrix": conf.tolist(),
        "Classification_Report": report
    }

    # Extract coefficients
    coefs = pd.Series(
        pipeline.named_steps["logreg"].coef_.flatten(),
        index=selected_features,
        name="Coefficient"
    ).sort_values(ascending=False)
    intercept = pipeline.named_steps["logreg"].intercept_[0]

    # Display results
    print("\n=== Final Logistic Regression Results (Full Dataset) ===")
    print(f"AUC: {auc:.3f}")
    print(f"Accuracy: {acc:.3f}")
    print(f"McFadden R²: {r2_mcf:.3f}")
    print(f"Nagelkerke R²: {r2_nag:.3f}")
    print("\nConfusion Matrix:\n", conf)
    print("\nClassification Report:\n", report)
    print(f"\nIntercept: {intercept:.4f}")
    print("\nTop Coefficients:\n", coefs.head(10))

    # Save outputs
    coefs_df = coefs.reset_index().rename(columns={'index': 'Feature'})
    coefs_df.to_csv(coef_file, index=False)
    with open(metrics_file, "w") as f:
        json.dump(metrics, f, indent=4)
    joblib.dump(pipeline, model_file)

    print(f"\nSaved coefficients to: {coef_file}")
    print(f"Saved metrics to: {metrics_file}")
    print(f"Saved model to: {model_file}")

    return pipeline, metrics, coefs_df


def plot_logistic_coefficients(coefs_df, title="Logistic Regression Coefficients", save_path=None):
    """
    Plot logistic regression coefficients as a forest plot.

    Parameters
    ----------
    coefs_df : pd.DataFrame
        DataFrame with columns ["Feature", "Coefficient"].
    title : str, optional
        Title of the plot.
    save_path : str or None, optional
        If provided, saves the figure to this path.
    """

    # --- Basic setup ---
    df = coefs_df.copy()
    df["Sign"] = np.where(df["Coefficient"] > 0, "Positive", "Negative")
    df = df.sort_values("Coefficient", ascending=True)

    plt.figure(figsize=(8, max(6, 0.25 * len(df))))  # dynamic height for #features
    sns.set(style="whitegrid")

    # --- Plot ---
    ax = sns.barplot(
        data=df,
        x="Coefficient",
        y="Feature",
        hue="Sign",
        palette={"Positive": "#4CAF50", "Negative": "#E53935"},
        dodge=False
    )

    # --- Reference line at 0 ---
    plt.axvline(x=0, color="black", linestyle="--", linewidth=1)

    # --- Labels & title ---
    plt.title(title, fontsize=14, pad=15)
    plt.xlabel("Coefficient value", fontsize=12)
    plt.ylabel("")
    plt.legend(title="Effect direction", loc="lower right")

    plt.tight_layout()

    # --- Save or show ---
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches="tight")
        print(f"Forest plot saved to: {save_path}")
    else:
        plt.show()


if __name__ == '__main__':
    selected_features = [
        "t_stopword",
        "n_PUNCT_PunctType_Brck",
        "n_dependency_punct",
        "n_punct",
        "n_dependency_amod",
        "n_PROPN_Number_Plur",
        "avg_aoa",
        "n_dependency_advcl",
        "corr_verb_var",
        "n_part",
        "n_high_Head_sensorimotor",
        "n_date",
        "n_VERB_VerbForm_Fin",
        "n_propn",
        "n_org",
        "n_PROPN_Number_Sing",
        "n_PRON_PronType_Prs",
        "simpsons_d",
        "mattr",
        "n_dependency_case",
        "n_dependency_prep",
        "n_pron",
        "n_PUNCT_PunctType_Comm",
        "entropy",
        "n_dependency_compound",
        "n_high_intensity_anger",
        "n_dependency_conj",
        "n_high_intensity_trust",
        "n_PUNCT_PunctType_Dash",
        "avg_word_length",
        "n_dependency_poss",
        "avg_concreteness",
        "n_dependency_nsubjpass",
        "corr_num_var",
        "n_dependency_neg",
        "n_DET_Definite_Def",
        "n_NOUN_Number_Plur",
        "n_high_intensity_surprise",
        "n_sconj",
        "n_aux",
        "n_high_concreteness",
        "n_VERB_Number_Sing",
        "n_dependency_dobj",
        "n_dependency_aux",
        "n_high_Gustatory_sensorimotor",
        "n_high_Foot_leg_sensorimotor",
        "n_dependency_relcl",
        "tree_depth",
        "n_dependency_advmod",
        "n_high_Auditory_sensorimotor",
        "n_dependency_mark",
        "n_dependency_expl",
        "n_ADJ_Degree_Pos",
        "corr_noun_var",
        "n_person",
        "corr_det_var",
        "tree_branching",
        "n_PRON_PronType_Dem",
        "corr_adj_var",
        "n_adv",
        "n_VERB_VerbForm_Part",
        "n_adj"
    ]
    parser = argparse.ArgumentParser(description="Full Model.")
    parser.add_argument("--input_t1", type=str, required=True, help="Path to T1 parquet file")
    parser.add_argument("--input_t2", type=str, required=True, help="Path to T2 parquet file")
    args = parser.parse_args()
    df_t1 = pd.read_parquet(args.input_t1)
    df_t2 = pd.read_parquet(args.input_t2)
    df_t1["after"] = 0
    df_t2["after"] = 1
    feature_df = pd.concat([df_t1, df_t2], axis=0)
    target = feature_df["after"]
    feature_df = feature_df.drop(columns=["after"], errors="ignore")
    feature_df = get_clean_feature_df(feature_df, selected_features)
    fit_final_logistic_regression_unpenalized(X_full=feature_df, y_full=target, selected_features=selected_features)
    print("Done.")
