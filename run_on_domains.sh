#!/usr/bin/env bash
# Run LFTK + ELFEN feature extractors on the 4 domain CSVs.
#
# Inputs : data/data-for-perplexity/domain-samples/for-perplexity/*.csv
# Outputs: ScientificCommunication/outputs_domains/<dataset>__{lftk,elfen}.parquet
#
# Usage:
#   bash run_on_domains.sh                       # both extractors, all domains
#   EXTRACTORS=lftk bash run_on_domains.sh       # only lftk
#   DOMAINS="arxiv_abstracts_100" bash run_on_domains.sh  # subset

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="${VENV:-/mimer/NOBACKUP/groups/naiss2024-6-297/narrative-coherence-next/coherence-next}"
DATA_DIR="${DATA_DIR:-/mimer/NOBACKUP/groups/naiss2024-6-297/narrative-coherence-next/data/data-for-perplexity/domain-samples/for-perplexity}"
OUT_DIR="${OUT_DIR:-${REPO_DIR}/outputs_domains}"
TEXT_COL="${TEXT_COL:-text}"
EXTRACTORS="${EXTRACTORS:-lftk}"  # elfen disabled: requires numpy==1.26.4, no Python 3.13 wheel
DOMAINS_DEFAULT="arxiv_abstracts_100 congress_politics_2026_lines_100 human_wp_stories_100 news_wsj_100"
DOMAINS="${DOMAINS:-${DOMAINS_DEFAULT}}"

mkdir -p "${OUT_DIR}"

# shellcheck source=/dev/null
source "${VENV}/bin/activate"

for ds in ${DOMAINS}; do
  csv="${DATA_DIR}/${ds}.csv"
  if [[ ! -f "${csv}" ]]; then
    echo "skip ${ds}: missing ${csv}"
    continue
  fi
  for ex in ${EXTRACTORS}; do
    out="${OUT_DIR}/${ds}__${ex}.parquet"
    if [[ -f "${out}" ]]; then
      echo "exists ${out} (skip)"
      continue
    fi
    echo "===== ${ex} on ${ds} ====="
    case "${ex}" in
      lftk)
        python "${REPO_DIR}/feature_analysis/extract_features_lftk.py" \
          --data_path "${csv}" --text_column "${TEXT_COL}" \
          --output_path "${out}" --data_type csv
        ;;
      elfen)
        python "${REPO_DIR}/feature_analysis/extract_features_elfen.py" \
          --data_path "${csv}" --text_column "${TEXT_COL}" \
          --output_path "${out}" --data_type csv --csv_separator ','
        ;;
      *)
        echo "unknown extractor: ${ex}" >&2; exit 1 ;;
    esac
  done
done

echo "done. outputs in ${OUT_DIR}"
