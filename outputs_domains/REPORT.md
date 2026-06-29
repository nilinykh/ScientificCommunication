# LFTK Domain Analysis — Report

Adapted from Miletić & Falk (LREC 2026), *What are LLMs doing to scientific communication?*
[arXiv:2605.19936](https://arxiv.org/pdf/2605.19936v1)

## 1. Setup

- **Domains (4):** `arxiv_abstracts_100`, `congress_politics_2026_lines_100`, `human_wp_stories_100`, `news_wsj_100`
- **Sample size:** 100 documents per domain
- **Feature extractor:** [LFTK](https://github.com/brucewlee/lftk) (57 numeric features)
- **Source files:** `outputs_domains/<domain>__lftk.parquet`

> elfen extraction has not been run yet; only LFTK results are analyzed here.

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

**Reading:** abstracts are dense/short; stories are longest; politics has the shortest *sentences* (many short lines from speeches).

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

**Reading:** essentially a stories-only signal ("oh!", "hey", "wow"). High `rel_gap` (3.46) is inflated by the near-zero baseline.

### 4.4 Symbols (`*_sym_var`)

| Feature | arxiv | politics | stories | wsj |
|---|---:|---:|---:|---:|
| `corr_sym_var` | 0.17 | 0.08 | 0.14 | 0.33 |

**Reading:** symbols ($, %, §, ticker chars) are a **WSJ** marker; politics minimal.

## 6. Domain "fingerprints"

| Domain | Length | Lexical diversity | Distinctive markers |
|---|---|---|---|
| **arXiv abstracts** | Very short | Low (technical jargon, formulaic) | Few interjections, moderate symbols |
| **Congress politics (lines)** | Short utterances | Lowest overall | Highest `simp_punct_var` (short → punct-dense) |
| **Human WP stories** | Longest | Highest (adv, sconj, intj) | Only domain with interjections |
| **WSJ news** | Long-ish | Moderate–high | Highest symbol diversity ($, %, tickers) |