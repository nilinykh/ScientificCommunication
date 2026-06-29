"""Extract texts from linkappend conll_to_json jsonlines for the smallest qwen
(qwen3vl-4b) and human_human, joining tokens from the `sentences` field.

Output: outputs_models/csvs/<name>.csv with a 'text' column.
Names: human_human, qwen4b_writer, qwen4b_journalist, qwen4b_advisor
"""
import csv
import json
from pathlib import Path

SRC = Path('/mimer/NOBACKUP/groups/naiss2024-6-297/narrative-coherence-next/data/results/linkappend-out/conll_to_json')
OUT = Path('/mimer/NOBACKUP/groups/naiss2024-6-297/ScientificCommunication/outputs_models/csvs')
OUT.mkdir(parents=True, exist_ok=True)

FILES = {
    'human_human': 'human_human_test_snapshots__local_json-nopound_pred.jsonlines',
    'qwen4b_writer': 'qwen3vl-4b_original-system-writer_test_snapshots__local_json-nopound_pred.jsonlines',
    'qwen4b_journalist': 'qwen3vl-4b_original-system-journalist_test_snapshots__local_json-nopound_pred.jsonlines',
    'qwen4b_advisor': 'qwen3vl-4b_original-system-advisor_test_snapshots__local_json-nopound_pred.jsonlines',
}


def doc_text(obj):
    sents = obj.get('sentences', [])
    return ' '.join(' '.join(toks) for toks in sents).strip()


for name, fname in FILES.items():
    path = SRC / fname
    rows = []
    with path.open() as f:
        for line in f:
            obj = json.loads(line)
            t = doc_text(obj)
            if t:
                rows.append({'doc_key': obj.get('doc_key', ''), 'text': t})
    out = OUT / f'{name}.csv'
    with out.open('w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=['doc_key', 'text'])
        w.writeheader()
        w.writerows(rows)
    avg = sum(len(r['text'].split()) for r in rows) / max(len(rows), 1)
    print(f'{out.name}: {len(rows)} docs, mean {avg:.0f} tokens')
