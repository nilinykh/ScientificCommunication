## Before running anything

- You need `narrative-coherence-next` repo

## Minimal order to rerun the analysis

If you want the full set of local outputs again, run the commands in this order from the repo root.

### 1. Human domains: feature extraction

```bash
bash run_on_domains.sh
```

What this does:
- runs LFTK on the 4 human-domain CSVs
- writes feature tables to `outputs_domains/`

Main files produced or refreshed:
- `outputs_domains/*__lftk.parquet`
- `outputs_domains/summary_lftk_means.csv`
- `outputs_domains/summary_lftk_long.csv`
- `outputs_domains/topdiff_lftk.csv`

### 2. Human domains: lexical preparation and pairwise comparisons

```bash
bash run_lexical_on_domains.sh
```

What this does:
- lemmatizes and tokenizes the 4 human-domain datasets
- builds 1-gram and 5-gram frequency tables
- computes pairwise log-likelihood comparisons for all domain pairs

Main files produced or refreshed:
- `outputs_lexical/*_tokenized_lower.txt`
- `outputs_lexical/*_lemmatized_lower.txt`
- `outputs_lexical/*_1grams_freqs.txt`
- `outputs_lexical/*_5grams_freqs.txt`
- `outputs_lexical/*_inner_ll.parquet`

### 3. Model texts: extract the source CSVs

```bash
python extract_model_texts.py
```

What this does:
- pulls `human_human` and the qwen 4b role outputs from linkappend JSONL files
- writes plain CSVs to `outputs_models/csvs/`

Main files produced or refreshed:
- `outputs_models/csvs/human_human.csv`
- `outputs_models/csvs/qwen4b_writer.csv`
- `outputs_models/csvs/qwen4b_journalist.csv`
- `outputs_models/csvs/qwen4b_advisor.csv`

### 4. Model texts: feature extraction and within-set lexical comparisons

```bash
bash run_on_models.sh
```

What this does:
- runs LFTK on the model and `human_human` CSVs
- lemmatizes them for lexical analysis
- computes the model-vs-model and model-vs-`human_human` LL comparisons defined in the script

Main files produced or refreshed:
- `outputs_models/*__lftk.parquet`
- `outputs_models/summary_all_lftk_means.csv`
- `outputs_models/topdiff_lftk_all.csv`
- `outputs_models/topdiff_lftk_modelonly.csv`
- `outputs_lexical_models/*_tokenized_lower.txt`
- `outputs_lexical_models/*_lemmatized_lower.txt`
- `outputs_lexical_models/*_inner_ll.parquet`

### 5. Cross comparisons between model outputs and selected human domains

```bash
bash run_cross_model_human.sh
```

What this does:
- adds the extra qwen-to-human lexical comparisons not covered by `run_on_models.sh`

Check the script if you want to know the exact pairs; this is the one to rerun when you want the cross-domain lexical tables in `outputs_lexical_models/`.

### 6. Refresh the simple feature summaries

```bash
python analyze_domain_features.py
python analyze_model_features.py
```

What this does:
- recomputes the summary CSVs used for inspection
- prints the largest feature gaps to the terminal

## What to inspect after the runs

If you only need the high-level picture, look here first:

1. `outputs_models/summary_all_lftk_means.csv`
2. `outputs_domains/summary_lftk_means.csv`
3. `outputs_models/topdiff_lftk_all.csv`
4. `outputs_domains/topdiff_lftk.csv`

If you want the written interpretation:

1. [FINDINGS.md](./FINDINGS.md) for the longer working notes
2. [findings_simple.txt](./findings_simple.txt) for the short summary
3. `outputs_domains/REPORT.md` for the human-domain write-up

If you want to inspect lexical differences interactively:

1. open `outputs_domains/domain_analysis.ipynb`
2. for human-only comparisons, use `../outputs_lexical`
3. for qwen/human comparisons, switch the notebook path to `../outputs_lexical_models`

## Quick orientation: which script does what

- `run_on_domains.sh`: LFTK on the 4 human-domain CSVs
- `run_lexical_on_domains.sh`: lexical preprocessing and LL for the 4 human domains
- `extract_model_texts.py`: converts local JSONL model outputs into CSVs
- `run_on_models.sh`: LFTK plus lexical pipeline for model outputs
- `run_cross_model_human.sh`: extra model-vs-human lexical comparisons
- `analyze_domain_features.py`: domain-level summary tables
- `analyze_model_features.py`: model-level summary tables

## Notes

- `FINDINGS.md` is analysis prose, not a runbook.
- `findings_simple.txt` is the short version to skim first.
