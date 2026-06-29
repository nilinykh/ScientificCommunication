



## D. Coherence handles — features you could tune

Most actionable knobs ranked by how cleanly they separate human/machine or domains:

1. **Interjections** — easy categorical knob. Inject ~0.5 interjections/100 words to make text feel like an oral / first-person story. Absent: machine, news, arxiv. Present: human stories.
2. **Symbol density** ($, %, §, ¤, numeric tickers) — adds news/finance register. Currently 0 for qwen.
3. **Subordinator variety** (because/although/while/since/whereas/unless) — bumps `corr_sconj_var`. Drives perceived argumentative or narrative complexity. Politics oddly *low* (formulaic speeches).
4. **Adverb tail** — extend adverb vocabulary beyond the qwen go-tos ("intently/slightly/softly/quietly"). Add discourse adverbs ("however, therefore, nonetheless, meanwhile").
5. **Content/function word balance** — qwen tends to be content-dense; raising the stopword ratio (`the/of/and/that`) to ~0.46–0.50 makes it read more story-like rather than camera-script-like.
6. **Length variability** — vary doc length: arxiv-short (~150 wd), narrative-long (~600 wd). Qwen is stuck at ~400.
7. **Vocabulary diversification** — qwen overuses scene-descriptive nouns (`eye/face/hand/room/light`). For domain-specific feel, *replace* these with field-specific lexicon (finance: `share, earning, quarter, rate`; news: `say, report, year, official`; arxiv: `show, model, energy, propose`).
8. **5-gram phrase templates** — qwen narratives repeat formulaic strings (look at qwen-vs-qwen 5-gram LL; the three roles share many top n-grams like "his face etched with the"). Breaking these templates would help.

---

## E. Coherence interpretation (relating to features)

- **Local coherence** (the paper's main interest) is what `corr_sconj_var` and adverb tails partially proxy: subordinators and discourse adverbs mark *how* clauses link. Qwen produces parataxis (lists of observations) where humans use hypotaxis (because, while, although). Plausible directional finding: human stories have higher *local* coherence per LFTK structural features; qwen has higher *content density* but flatter clause structure.
- **Global / thematic coherence** is not captured by LFTK at all. Use the paper's w2v / clustering pipeline if you want that — needs much more data per corpus (skipped here).
- **Role-conditioning hypothesis** falsified on this slice: qwen3vl-4b's "advisor/journalist/writer" produce structurally identical text. Coherence is set by the *model*, not the *role tag*. The few lexical shifts between roles are mostly cosmetic adjectives.
- **Domain register matters more than role**: switching qwen role moves the texts by tens of LL points pairwise; switching human domain (arxiv↔politics) moves thousands. → Human domains are much further apart than qwen roles.

---

## F. Open questions / next experiments

- [ ] Run elfen on the same texts (needs Python 3.11/3.12 venv, numpy 1.26.4). Compare with LFTK.
- [ ] Test the *tunable* hypothesis: take qwen output, regenerate with explicit instruction "use at least 3 interjections, 5 subordinators, vary adverb vocabulary" — re-measure features. Does it become more human-like by these metrics?
- [ ] Scale up to all qwen sizes (4b/8b/30b) — does coherence-feature gap close with size?
- [ ] Include gemma + internvl for cross-architecture comparison (data already on disk under linkappend-out).
- [ ] Build n-gram-template detector to flag qwen's clichés ("his face etched with the weight of", "the dimly lit room", "his gaze fixed on") so you can quantify formulaicity.

---

## G. What to run, in order

> All scripts live at the repo root: [/ScientificCommunication](.)

1. **Once, to (re)generate the data:**
   - `bash run_on_domains.sh` — LFTK on the 4 human domains. Outputs to [outputs_domains/](outputs_domains/).
   - `bash run_lexical_on_domains.sh` — lemmatise + n-gram + 6-pair LL for the 4 human domains. Outputs to [outputs_lexical/](outputs_lexical/).
   - `python extract_model_texts.py` — pulls qwen3vl-4b texts (3 roles) + `human_human` out of the linkappend JSONLs into [outputs_models/csvs/](outputs_models/csvs/).
   - `bash run_on_models.sh` — LFTK on the 4 model/human CSVs + lexical prep + 6 in-set LL pairs.
   - `bash run_cross_model_human.sh` — extra 7 LL pairs linking qwen roles to relevant human domains.
   - `python analyze_domain_features.py` — produces topdiff/summary CSVs in [outputs_domains/](outputs_domains/).

2. **Then look at:**
   - [outputs_models/summary_all_lftk_means.csv](outputs_models/summary_all_lftk_means.csv) — all sets × all features. Best entry point for tabular comparison.
   - [outputs_domains/REPORT.md](outputs_domains/REPORT.md) — written-up interpretation of the human-only LFTK analysis.
   - [outputs_domains/domain_analysis.ipynb](outputs_domains/domain_analysis.ipynb) — interactive lexical analysis (4 human domains).
   - **This file** ([FINDINGS.md](FINDINGS.md)) — the model-vs-human brainstorm.

3. **To explore further:**
   - Open [outputs_domains/domain_analysis.ipynb](outputs_domains/domain_analysis.ipynb), change `LEX_DIR` to `../outputs_lexical_models` and set `BASE`/`TARGET` to any qwen↔human pair → reuse the same plots.
   - Or compute custom comparisons on the parquets directly — they all share the same schema: `target | lemma | pos | freq1 | freq2 | ratio_t1 | ratio_t2 | ll`.

---

## H. File map (cheat sheet)

| What | Where |
|---|---|
| Human-domain LFTK | [outputs_domains/*__lftk.parquet](outputs_domains/) |
| Human-domain LFTK summaries | [outputs_domains/summary_lftk_means.csv](outputs_domains/summary_lftk_means.csv), [topdiff_lftk.csv](outputs_domains/topdiff_lftk.csv) |
| Model + hh LFTK | [outputs_models/*__lftk.parquet](outputs_models/) |
| Combined means (all 8 sets) | [outputs_models/summary_all_lftk_means.csv](outputs_models/summary_all_lftk_means.csv) |
| Human-domain pairwise LL | [outputs_lexical/*_inner_ll.parquet](outputs_lexical/) |
| Model-vs-model LL + Model-vs-human LL | [outputs_lexical_models/*_inner_ll.parquet](outputs_lexical_models/) |
| Source CSVs (human) | `/mimer/NOBACKUP/groups/naiss2024-6-297/narrative-coherence-next/data/data-for-perplexity/domain-samples/for-perplexity/` |
| Source JSONLs (qwen/human_human) | `/mimer/NOBACKUP/groups/naiss2024-6-297/narrative-coherence-next/data/results/linkappend-out/conll_to_json/` |
| Extracted model CSVs | [outputs_models/csvs/](outputs_models/csvs/) |
| Run scripts | [run_on_domains.sh](run_on_domains.sh), [run_lexical_on_domains.sh](run_lexical_on_domains.sh), [run_on_models.sh](run_on_models.sh), [run_cross_model_human.sh](run_cross_model_human.sh) |
| Extraction helper | [extract_model_texts.py](extract_model_texts.py) |
