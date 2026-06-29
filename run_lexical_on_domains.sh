#!/usr/bin/env bash
# Run lexical prep pipeline on the 4 domain CSVs, mirroring what
# the paper does for cacl_t1 vs sample_gpt35.
#
# Steps per domain:
#   1) sentence-segment + lemmatize + lowercase  -> <ds>_lemmatized_lower.txt
#   2) unigram frequency count                   -> <ds>_lemmatized_lower_1grams_freqs.txt
#   3) 5-gram frequency count                    -> <ds>_lemmatized_lower_5grams_freqs.txt
#
# Then for every pair (a,b):
#   4) log-likelihood unigrams -> outputs_lexical/<a>_vs_<b>_1grams_freqs_inner_ll.parquet
#   5) log-likelihood 5-grams  -> outputs_lexical/<a>_vs_<b>_5grams_freqs_inner_ll.parquet
#
# Skipped (require much more data than 100 docs/domain):
#   - word2vec training and neighborhood density
#   - contextual clustering
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="${VENV:-/mimer/NOBACKUP/groups/naiss2024-6-297/narrative-coherence-next/coherence-next}"
DATA_DIR="${DATA_DIR:-/mimer/NOBACKUP/groups/naiss2024-6-297/narrative-coherence-next/data/data-for-perplexity/domain-samples/for-perplexity}"
OUT_DIR="${OUT_DIR:-${REPO_DIR}/outputs_lexical}"
PREP="${REPO_DIR}/prep_data"
DOMAINS="${DOMAINS:-arxiv_abstracts_100 congress_politics_2026_lines_100 human_wp_stories_100 news_wsj_100}"

mkdir -p "${OUT_DIR}"
# shellcheck disable=SC1091
source "${VENV}/bin/activate"

cd "${PREP}"  # scripts use `from utils import read_pandas`

# --- 1) sentence/lemma/lowercase ---
for ds in ${DOMAINS}; do
  out="${OUT_DIR}/${ds}_lemmatized_lower.txt"
  if [[ -f "${out}" ]]; then
    echo "exists ${out} (skip)"
    continue
  fi
  echo "===== lemmatize ${ds} ====="
  python make_one_sentence_per_line.py \
    "${DATA_DIR}/${ds}.csv" "${OUT_DIR}" "${ds}" \
    --col_name text --lowercase --processes 1
done

# --- 2,3) frequency counts ---
for ds in ${DOMAINS}; do
  base="${OUT_DIR}/${ds}_lemmatized_lower"
  for n in 1 5; do
    out="${base}_${n}grams_freqs.txt"
    if [[ -f "${out}" ]]; then
      echo "exists ${out} (skip)"
      continue
    fi
    echo "===== ${n}-gram counts ${ds} ====="
    python make_frequency_count.py "${base}.txt" "${OUT_DIR}" --ngrams "${n}"
  done
done

# --- 4,5) pairwise log-likelihood ---
arr=(${DOMAINS})
for ((i=0; i<${#arr[@]}; i++)); do
  for ((j=i+1; j<${#arr[@]}; j++)); do
    a="${arr[i]}"
    b="${arr[j]}"
    for n in 1 5; do
      out_name="${a}_vs_${b}_${n}grams_freqs_inner_ll.parquet"
      out="${OUT_DIR}/${out_name}"
      if [[ -f "${out}" ]]; then
        echo "exists ${out} (skip)"
        continue
      fi
      echo "===== LL ${n}-gram ${a} vs ${b} ====="
      EXTRA=()
      if [[ "${n}" == "5" ]]; then
        EXTRA+=(--unigram_file1 "${OUT_DIR}/${a}_lemmatized_lower_1grams_freqs.tsv"
                --unigram_file2 "${OUT_DIR}/${b}_lemmatized_lower_1grams_freqs.tsv")
      fi
      python make_frequency_loglikelihood.py \
        "${OUT_DIR}/${a}_lemmatized_lower_${n}grams_freqs.tsv" \
        "${OUT_DIR}/${b}_lemmatized_lower_${n}grams_freqs.tsv" \
        "${OUT_DIR}" --join inner --out_name "${out_name}" \
        "${EXTRA[@]}"
    done
  done
done

echo "done. outputs in ${OUT_DIR}"
