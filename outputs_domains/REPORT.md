# LFTK Domain Analysis — Report

Adapted from Miletić & Falk (LREC 2026), *What are LLMs doing to scientific communication?*
[arXiv:2605.19936](https://arxiv.org/pdf/2605.19936v1)

## 1. Setup

- **Domains (4):** `arxiv_abstracts_100`, `congress_politics_2026_lines_100`, `human_wp_stories_100`, `news_wsj_100`
- **Sample size:** 100 documents per domain
- **Feature extractor:** [LFTK](https://github.com/brucewlee/lftk) (57 numeric features)
- **Source files:** `outputs_domains/<domain>__lftk.parquet`

> elfen extraction has not been run yet; only LFTK results are analyzed here.

## 2. Differences from the paper

| Paper | This analysis |
|---|---|
| Binary contrast (naturalistic *t1* vs LLM-paraphrased *t2*) | 4-way domain contrast |
| Elastic-net logistic regression w/ stability selection | Descriptive ranking + Cohen's d |
| log-likelihood on word frequencies, word2vec density, clustering | **Not run** — requires `prep_data/` pipeline + 2-corpus design |
| Pairwise human preference annotations | N/A |
| Both LFTK + elfen | LFTK only |

## 3. LFTK feature naming key

LFTK features follow `<prefix>_<POS|unit>_<stat>`:

- `t_X` — **total count** of `X` in document (raw)
- `simp_X_var` — *simple* TTR: unique_X / total_X
- `corr_X_var` — *corrected* TTR: unique_X / sqrt(2·total_X) (length-robust)
- `root_X_var` — *root* TTR: unique_X / sqrt(total_X)
- POS tokens: `noun`, `verb`, `adj`, `adv`, `sconj` (subordinating conj), `cconj`, `intj` (interjection), `sym` (symbol), `punct`, `stopword`, `word`, `sent`

## 4. Top features by `rel_gap` — interpretation

`rel_gap = (max − min of domain means) / mean(|domain means|)`. Higher = more discriminative *relative to typical magnitude*.

### 4.1 Length features (`t_*`)

| Feature | arxiv | politics | stories | wsj |
|---|---:|---:|---:|---:|
| `t_word` | 155.0 | 285.8 | 613.4 | 554.5 |
| `t_sent` | 5.6 | 11.5 | 40.2 | 21.7 |
| `t_punct` | 17.4 | 41.4 | 96.4 | 75.1 |
| `t_stopword` | 58.8 | 114.4 | 286.1 | 204.4 |

**Reading:** abstracts are dense/short; stories are longest; politics has the shortest *sentences* (many short lines from speeches). These features are heavily correlated — they essentially measure document length.

> ⚠️ Several "top" features by `rel_gap` are length-driven. Drop or length-normalize when you want stylistic signal.

### 4.2 Lexical diversity (`*_var` for content POS)

| Feature | arxiv | politics | stories | wsj |
|---|---:|---:|---:|---:|
| `corr_adv_var` | 1.12 | 0.53 | 2.63 | 1.87 |
| `corr_sconj_var` | 0.61 | 0.20 | 1.11 | 0.68 |

**Reading:** **stories** use a much wider variety of adverbs ("suddenly", "barely", "however") and subordinators ("because", "although", "while") → narrative complexity. **Politics** is the most repetitive/formulaic.

### 4.3 Interjections (`*_intj_var`)

| Feature | arxiv | politics | stories | wsj |
|---|---:|---:|---:|---:|
| `corr_intj_var` | 0.00 | 0.02 | 0.61 | 0.07 |

**Reading:** essentially a stories-only signal ("oh!", "hey", "wow"). High `rel_gap` (3.46) is inflated by the near-zero baseline — treat as **categorical** (present / absent) rather than graded.

### 4.4 Symbols (`*_sym_var`)

| Feature | arxiv | politics | stories | wsj |
|---|---:|---:|---:|---:|
| `corr_sym_var` | 0.17 | 0.08 | 0.14 | 0.33 |

**Reading:** symbols ($, %, §, ticker chars) are a **WSJ** marker; politics minimal.

## 5. Redundancy in the feature set

- `simp_X_var`, `corr_X_var`, `root_X_var` for the same POS share a numerator → near-identical rankings (note `root_intj_var` and `corr_intj_var` have identical `rel_gap` = 3.4627).
  → **Keep only `corr_*_var`** (length-robust) when reporting.
- `t_word`, `t_sent`, `t_punct`, `t_stopword` are correlated length proxies.
  → Keep `t_word` as the canonical length variable; convert others to ratios `t_punct / t_word`, etc.

After deduplication you have roughly **20–25 informative features** instead of 57.

## 6. Domain "fingerprints"

| Domain | Length | Lexical diversity | Distinctive markers |
|---|---|---|---|
| **arXiv abstracts** | Very short | Low (technical jargon, formulaic) | Few interjections, moderate symbols |
| **Congress politics (lines)** | Short utterances | Lowest overall | Highest `simp_punct_var` (short → punct-dense) |
| **Human WP stories** | Longest | Highest (adv, sconj, intj) | Only domain with interjections |
| **WSJ news** | Long-ish | Moderate–high | Highest symbol diversity ($, %, tickers) |

## 7. Caveats & suggested next steps

1. **Run elfen** to compare with LFTK (the paper finds elfen captures different stylistic dimensions).
2. **Length-normalize** all `t_*` counts by `t_word` before drawing stylistic conclusions.
3. **Statistical rigor:** replace `rel_gap` with one-way ANOVA / Kruskal–Wallis + Cohen's d effect sizes (see companion notebook `domain_analysis.ipynb`).
4. **n=100 per domain is small.** Pairwise comparisons should report CIs, not just point estimates.
5. To approximate the paper's elastic-net pipeline, you'd need a **binary** contrast — e.g. arxiv-vs-rest or stories-vs-news — and a much larger sample. Out of scope here.
6. **Lexical analysis was run** for all 6 domain pairs (1-gram + 5-gram log-likelihood). The paper's `analysis_main.ipynb`/`analysis_ngrams.ipynb` are not directly runnable (they expect `cacl_t1`/`sample_gpt35` filenames) — instead use the companion notebook [domain_analysis.ipynb](domain_analysis.ipynb). Word2vec neighborhood density and contextual clustering are **not** computed; with only ~100 docs per domain those embeddings would be too noisy to be meaningful.

## 9. Lexical analysis pipeline (run by `run_lexical_on_domains.sh`)

Per domain:
1. spaCy sentence-segment + lemmatize + POS-tag + lowercase → [outputs_lexical/](../outputs_lexical/)`<ds>_lemmatized_lower.txt`
2. Unigram + 5-gram frequency counts → `<ds>_lemmatized_lower_{1,5}grams_freqs.txt`

Per pair (6 unordered pairs):

3. Pairwise log-likelihood (per [Rayson & Garside](https://ucrel.lancs.ac.uk/llwizard.html)) → `<a>_vs_<b>_{1,5}grams_freqs_inner_ll.parquet`

Schema of the LL parquets: `target | lemma | pos | freq1 | freq_norm1 | freq2 | freq_norm2 | ratio_t1 | ratio_t2 | logratio_t1 | logratio_t2 | ll`

Significance threshold: `LL > 15.13` (chi-square 1 df, p < 0.0001).

## 8. Files in `outputs_domains/`

| File | Contents |
|---|---|
| `<domain>__lftk.parquet` | Raw per-document features for each of the 4 domains |
| `summary_lftk_means.csv` | Per-domain mean of every numeric feature (57 × 4) |
| `summary_lftk_long.csv` | Long-form mean/std/median per (domain, feature) |
| `topdiff_lftk.csv` | Features ranked by `rel_gap` |
| `REPORT.md` | **This file** |
| `domain_analysis.ipynb` | Companion visualizations (see next section) |
