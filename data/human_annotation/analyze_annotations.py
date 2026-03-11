import tabulate

from scipy.stats import ttest_1samp, wilcoxon
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


def get_mapping(df):
    # Define mapping
    preference_score_map = {
        "human strong": 2,
        "human moderate": 1,
        "neutral": 0,
        "model moderate": -1,
        "model strong": -2
    }

    # Example for clarity preferences
    df["clarity_score"] = df["clarity_preference"].map(preference_score_map)

    # Drop rows with missing or unmapped values (optional safety)
    df = df.dropna(subset=["clarity_score"])
    df["convincingness_score"] = df["convincingness_preference"].map(preference_score_map)
    df = df.dropna(subset=["convincingness_score"])
    df["authenticity_score"] = df["authenticity_preference"].map(preference_score_map)
    df = df.dropna(subset=["authenticity_score"])
    df["excitement_score"] = df["excitement_preference"].map(preference_score_map)
    df = df.dropna(subset=["excitement_score"])
    return df


# Preference mapping
pref_map = {
    1: ("strong", "human"),
    2: ("moderate", "human"),
    3: ("moderate", "model"),
    4: ("strong", "model")
}


# Helper function
def get_preference(score, label):
    strength, favored = pref_map.get(score, ("neutral", None))
    if strength == "neutral":
        return "neutral"
    if label == "A=human":
        return f"{favored} {strength}"
    else:
        opposite = "model" if favored == "human" else "human"
        return f"{opposite} {strength}"


def get_aggregate(df):
    clarity_preferences = []
    authenticity_preferences = []
    convincingness_preferences = []
    excitement_preferences = []

    # Iterate through rows
    for _, row in df.iterrows():
        label = row["which_text_is_human"]

        clarity = (row["clarity_1"] + row["clarity_2"]) / 2
        authenticity = (row["authenticity_1"] + row["authenticity_2"]) / 2
        convincingness = (row["convincingness_1"] + row["convincingness_2"]) / 2
        excitement = (row["excitement_1"] + row["excitement_2"]) / 2

        clarity_preferences.append(get_preference(clarity, label))
        authenticity_preferences.append(get_preference(authenticity, label))
        convincingness_preferences.append(get_preference(convincingness, label))
        excitement_preferences.append(get_preference(excitement, label))

    df["clarity_preference"] = clarity_preferences
    df["authenticity_preference"] = authenticity_preferences
    df["convincingness_preference"] = convincingness_preferences
    df["excitement_preference"] = excitement_preferences
    return df


def compute_statistical_tests():
    """
    For each preference dimension, compute:
    Whether the mean preference score is significantly different from 0 (neutral) using a one-sample t-test.
    Whether the distribution of scores is significantly different from 0 using a Wilcoxon signed-rank test (nonparametric).
    The effect size (Cohen's d) for the mean preference score.
    --> To check whether there is a significant preference for human or model for each reading dimension.
    """
    df = pd.read_csv("data/human_annotation/human_annotations.csv")
    df = get_aggregate(df)

    df = get_mapping(df)
    for col in ["clarity_preferences", "authenticity_preferences", "convincingness_preferences",
                "excitement_preferences"]:
        score_col = col.replace("preferences", "score")
        scores = df[score_col].dropna()

        # --- Parametric test (as before) ---
        t_stat, p_value = ttest_1samp(scores, popmean=0)

        # --- Nonparametric alternative (Wilcoxon signed-rank test) ---
        # Note: zero_method='wilcox' ignores exact zeros (ties with no difference)
        w_stat, w_p_value = wilcoxon(scores, zero_method="wilcox", alternative="two-sided")

        # --- Effect size ---
        mean_score = scores.mean()
        std_dev = scores.std(ddof=1)
        cohens_d = mean_score / std_dev

        print(f"\n{score_col.replace('_', ' ').title()}")
        print(f"  Mean score: {mean_score:.2f}")
        print(f"  T-statistic: {t_stat:.3f},  p = {p_value:.3f}")
        print(f"  Wilcoxon statistic: {w_stat:.3f},  p = {w_p_value:.3f}")
        print(f"  Cohen's d: {cohens_d:.2f}")


def plot_preference_distribution(df, annot, id_col=None):
    """
    Plot the relative distribution of rating categories per dimension.
    Each column in `df` (except `id_col`) is assumed to represent one dimension
    containing categorical ratings such as:
    ['human_strong', 'human_moderate', 'neutral', 'model_moderate', 'model_strong'].
    """

    # Drop identifier column if present
    if id_col is not None and id_col in df.columns:
        df = df.drop(columns=[id_col])

    # Convert to long format
    df_melt = df.melt(var_name='dimension', value_name='rating')

    # Define consistent rating order
    rating_order = [
        "human strong",
        "human moderate",
        "neutral",
        "model moderate",
        "model strong"
    ]
    df_melt['rating'] = pd.Categorical(df_melt['rating'], categories=rating_order, ordered=True)
    print(df_melt.head())
    # Compute counts per (dimension, rating)
    # Compute relative frequencies
    counts = (
        df_melt.groupby(['dimension', 'rating'])
        .size()
        .reset_index(name='count')
    )
    counts['percent'] = (
            counts['count'] / counts.groupby('dimension')['count'].transform('sum') * 100
    )
    # dimension replace _preference with ""
    counts["dimension"] = counts["dimension"].str.replace("_preference", "").str.title()

    # Pivot for stacked plotting
    pivot_df = counts.pivot(index='dimension', columns='rating', values='percent').fillna(0)
    pivot_df = pivot_df[rating_order]  # ensure correct order

    # Define a color palette: blue → gray → red (human → neutral → model)
    colors = ["#3b5bdb", "#74c0fc", "#ced4da", "#ffa8a8", "#e03131"]

    # Plot horizontal stacked bars
    pivot_df.plot(
        kind='barh',
        stacked=True,
        color=colors,
        figsize=(8, 5),
        edgecolor='white'
    )

    plt.title("Preference Distribution per Dimension", fontsize=13)
    plt.xlabel("Percentage (%)")
    plt.ylabel("")
    plt.xlim(0, 100)
    plt.legend(title="Rating", bbox_to_anchor=(1.05, 1), loc='upper left')
    sns.despine(left=True, bottom=True)
    plt.tight_layout()
    # save figure
    plt.savefig(f"/Users/falkne/PycharmProjects/cacl-ocl/annotation_which_is_more/distribution_{annot}.png", dpi=300,
                bbox_inches="tight")
    # plt.show()


if __name__ == '__main__':
    df = pd.read_csv("data/human_annotation/human_annotations.csv")
    df = get_aggregate(df)
    print(tabulate.tabulate(df.head(), headers='keys', tablefmt='psql'))
    df = df[["annotator", "clarity_preference", "authenticity_preference", "convincingness_preference",
             "excitement_preference"]]
    # rename column "convincingness_preference" to "trustworthiness_preference"
    df = df.rename(columns={"convincingness_preference": "trustworthiness_preference"})
    plot_preference_distribution(df, annot="all", id_col="annotator")

