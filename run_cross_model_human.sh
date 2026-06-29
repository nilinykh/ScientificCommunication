#!/usr/bin/env bash
# Compute log-likelihood between qwen roles (outputs_lexical_models/)
# and human domains (outputs_lexical/). All freq files already exist.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="${VENV:-/mimer/NOBACKUP/groups/naiss2024-6-297/narrative-coherence-next/coherence-next}"
LEX_M="${REPO_DIR}/outputs_lexical_models"
LEX_H="${REPO_DIR}/outputs_lexical"
OUT="${LEX_M}"   # write cross-pair LL parquets here for convenience
PREP="${REPO_DIR}/prep_data"

# shellcheck disable=SC1091
source "${VENV}/bin/activate"
cd "${PREP}"

# Pairs: "<model_name> <human_domain>"
PAIRS=(
  "qwen4b_writer human_wp_stories_100"
  "qwen4b_writer arxiv_abstracts_100"
  "qwen4b_journalist news_wsj_100"
  "qwen4b_journalist congress_politics_2026_lines_100"
  "qwen4b_advisor news_wsj_100"
  "qwen4b_advisor congress_politics_2026_lines_100"
  "human_human human_wp_stories_100"
)

for pair in "${PAIRS[@]}"; do
  read -r m h <<< "${pair}"
  for k in 1 5; do
    out_name="${m}_vs_${h}_${k}grams_freqs_inner_ll.parquet"
    out_path="${OUT}/${out_name}"
    if [[ -f "${out_path}" ]]; then
      echo "exists ${out_path} (skip)"
      continue
    fi
    echo "===== LL ${k}-gram ${m} vs ${h} ====="
    EXTRA=()
    if [[ "${k}" == "5" ]]; then
      EXTRA+=(--unigram_file1 "${LEX_M}/${m}_lemmatized_lower_1grams_freqs.tsv"
              --unigram_file2 "${LEX_H}/${h}_lemmatized_lower_1grams_freqs.tsv")
    fi
    python make_frequency_loglikelihood.py \
      "${LEX_M}/${m}_lemmatized_lower_${k}grams_freqs.tsv" \
      "${LEX_H}/${h}_lemmatized_lower_${k}grams_freqs.tsv" \
      "${OUT}" --join inner --out_name "${out_name}" \
      "${EXTRA[@]}"
  done
done
echo "done."
