#!/usr/bin/env bash
# Run LFTK + lexical pipeline on the model CSVs (qwen3vl-4b roles + human_human).
#
# Inputs : outputs_models/csvs/*.csv (text column: 'text')
# Outputs:
#   - outputs_models/<name>__lftk.parquet
#   - outputs_lexical_models/<name>_lemmatized_lower.txt
#   - outputs_lexical_models/<name>_lemmatized_lower_{1,5}grams_freqs.tsv
#   - outputs_lexical_models/<a>_vs_<b>_{1,5}grams_freqs_inner_ll.parquet
#     for the pairs we care about.

set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="${VENV:-/mimer/NOBACKUP/groups/naiss2024-6-297/narrative-coherence-next/coherence-next}"
CSV_DIR="${REPO_DIR}/outputs_models/csvs"
LFTK_OUT="${REPO_DIR}/outputs_models"
LEX_OUT="${REPO_DIR}/outputs_lexical_models"
PREP="${REPO_DIR}/prep_data"
NAMES="human_human qwen4b_writer qwen4b_journalist qwen4b_advisor"

mkdir -p "${LFTK_OUT}" "${LEX_OUT}"
# shellcheck disable=SC1091
source "${VENV}/bin/activate"

# --- LFTK ---
for n in ${NAMES}; do
  out="${LFTK_OUT}/${n}__lftk.parquet"
  if [[ -f "${out}" ]]; then
    echo "exists ${out} (skip)"
    continue
  fi
  echo "===== LFTK ${n} ====="
  python "${REPO_DIR}/feature_analysis/extract_features_lftk.py" \
    --data_path "${CSV_DIR}/${n}.csv" --text_column text \
    --output_path "${out}" --data_type csv
done

# --- lexical prep ---
cd "${PREP}"
for n in ${NAMES}; do
  out="${LEX_OUT}/${n}_lemmatized_lower.txt"
  if [[ ! -f "${out}" ]]; then
    echo "===== lemmatize ${n} ====="
    python make_one_sentence_per_line.py \
      "${CSV_DIR}/${n}.csv" "${LEX_OUT}" "${n}" \
      --col_name text --lowercase --processes 1
  fi
  for k in 1 5; do
    base="${LEX_OUT}/${n}_lemmatized_lower"
    tsv="${base}_${k}grams_freqs.tsv"
    txt="${base}_${k}grams_freqs.txt"
    if [[ ! -f "${txt}" ]]; then
      echo "===== ${k}-gram counts ${n} ====="
      python make_frequency_count.py "${base}.txt" "${LEX_OUT}" --ngrams "${k}"
    fi
    if [[ ! -f "${tsv}" ]]; then
      ln -s "$(basename "${txt}")" "${tsv}"
    fi
  done
done

# --- pairwise LL (only the requested pairs) ---
# Format: "a b" pairs
PAIRS=(
  "human_human qwen4b_writer"
  "human_human qwen4b_journalist"
  "human_human qwen4b_advisor"
  "qwen4b_writer qwen4b_journalist"
  "qwen4b_writer qwen4b_advisor"
  "qwen4b_journalist qwen4b_advisor"
)
for pair in "${PAIRS[@]}"; do
  read -r a b <<< "${pair}"
  for k in 1 5; do
    out_name="${a}_vs_${b}_${k}grams_freqs_inner_ll.parquet"
    out="${LEX_OUT}/${out_name}"
    if [[ -f "${out}" ]]; then
      echo "exists ${out} (skip)"
      continue
    fi
    echo "===== LL ${k}-gram ${a} vs ${b} ====="
    EXTRA=()
    if [[ "${k}" == "5" ]]; then
      EXTRA+=(--unigram_file1 "${LEX_OUT}/${a}_lemmatized_lower_1grams_freqs.tsv"
              --unigram_file2 "${LEX_OUT}/${b}_lemmatized_lower_1grams_freqs.tsv")
    fi
    python make_frequency_loglikelihood.py \
      "${LEX_OUT}/${a}_lemmatized_lower_${k}grams_freqs.tsv" \
      "${LEX_OUT}/${b}_lemmatized_lower_${k}grams_freqs.tsv" \
      "${LEX_OUT}" --join inner --out_name "${out_name}" \
      "${EXTRA[@]}"
  done
done

echo "done."
