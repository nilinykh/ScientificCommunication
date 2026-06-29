"""Extract qwen-generated narratives from linkappend JSONL files.

For each role in {writer, journalist, banker, advisor}, combine across qwen
sizes (30b, 8b, 4b) and write a CSV with a single 'text' column whose rows are
the model-generated stories (the 'input' field with the 'coref: wb | _ ' prefix
stripped). Output: outputs_models/csvs/qwen_<role>.csv
"""
import csv
import json
import re
from pathlib import Path

DATA_OUT = Path('/mimer/NOBACKUP/groups/naiss2024-6-297/narrative-coherence-next/models/linkappend/data-out')
OUT_DIR = Path('/mimer/NOBACKUP/groups/naiss2024-6-297/ScientificCommunication/outputs_models/csvs')
OUT_DIR.mkdir(parents=True, exist_ok=True)

ROLES = ['writer', 'journalist', 'banker', 'advisor']
SIZES = ['30b', '8b', '4b']
PREFIX_RE = re.compile(r'^\s*coref:\s*wb\s*\|\s*_\s*')

for role in ROLES:
    rows = []
    for size in SIZES:
        path = DATA_OUT / f'qwen3vl-{size}_original-system-{role}' / 'test_snapshots__local_json-nopound_examples.jsonl'
        if not path.exists():
            print(f'skip missing {path}')
            continue
        with path.open() as f:
            for line in f:
                obj = json.loads(line)
                text = obj.get('input', '')
                text = PREFIX_RE.sub('', text).strip()
                if text:
                    rows.append({'size': size, 'text': text})
    out = OUT_DIR / f'qwen_{role}.csv'
    with out.open('w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=['size', 'text'])
        w.writeheader()
        w.writerows(rows)
    print(f'{out.name}: {len(rows)} rows  (sizes: {sorted(set(r["size"] for r in rows))})')
