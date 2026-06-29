# Findings & brainstorm — human vs machine text features

Data sources used:
- 4 human domains (n=100 each): arxiv, politics, wp_stories, wsj  → [outputs_domains/](outputs_domains/)
- linkappend human stories (n=20, very short captions): `hh_stories`  → [outputs_models/human_human__lftk.parquet](outputs_models/human_human__lftk.parquet)
- qwen3vl-4b role-conditioned narratives (n=20 each): `qwen_writer`, `qwen_journalist`, `qwen_advisor`  → [outputs_models/](outputs_models/)
- Pairwise log-likelihood: [outputs_lexical/](outputs_lexical/) (human-vs-human) and [outputs_lexical_models/](outputs_lexical_models/) (model-vs-model and model-vs-human)

> Always look at *_pw (per-word) or corr_*_var (length-robust) versions first.

---

## A. LFTK feature snapshot (length-normalised)

Means table (subset, key features) — full file at [outputs_models/summary_all_lftk_means.csv](outputs_models/summary_all_lftk_means.csv):

| feature | arxiv | politics | wp_stories | wsj | hh_stories | qwen_writer | qwen_journalist | qwen_advisor |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| t_word (length) | 155 | 286 | 613 | 554 | 83 | 390 | 422 | 398 |
| t_punct / word | .112 | .145 | .157 | .135 | .090 | .161 | .158 | .157 |
| t_stopword / word | .380 | .400 | **.466** | .369 | .495 | .412 | .408 | .400 |
| corr_adv_var | 1.12 | 0.53 | **2.63** | 1.87 | 1.01 | 1.89 | 1.92 | 1.90 |
| corr_sconj_var | 0.61 | 0.20 | **1.11** | 0.68 | 0.68 | 0.76 | 0.76 | 0.69 |
| corr_intj_var | 0.00 | 0.02 | **0.61** | 0.07 | 0.00 | 0.00 | 0.00 | 0.00 |
| corr_sym_var | 0.17 | 0.08 | 0.14 | **0.33** | 0.00 | 0.00 | 0.00 | 0.00 |
| corr_noun_var | 3.03 | 2.16 | 4.68 | 4.04 | 1.87 | **4.81** | 4.72 | 4.38 |
| corr_verb_var | 2.22 | 1.46 | **4.24** | 3.31 | 2.11 | 3.84 | 3.68 | 3.77 |
| corr_adj_var | 2.30 | 1.15 | 3.08 | 2.87 | 1.20 | 2.92 | **3.15** | 3.04 |

---

## B. Where human and qwen differ (the headline patterns)

1. **Interjections** (`corr_intj_var`) — only human wp_stories has them (0.61). Both qwen and human_human are flat zero. → "oh!", "hey", "wow" are a real human-narrative marker; qwen never uses them across any role.
2. **Symbols** (`corr_sym_var`) — WSJ has $/%/§ at 0.33. Qwen never produces them, even when asked to be journalist/advisor. → If you want qwen text to read "news-like", you'd need to coerce $/% generation.
3. **Adverb variety** (`corr_adv_var`) — human wp_stories 2.63 vs qwen_writer 1.89. Qwen uses adverbs at a moderate rate, but a *narrower* set ("intently", "slightly", "softly" repeat). Stories have wider tail ("suddenly", "barely", "however", "nervously"…).
4. **Subordination** (`corr_sconj_var`) — wp_stories 1.11, qwen_writer 0.76. Stories use more `because/although/while/whereas` → causal/contrastive complexity.
5. **POS variety where qwen exceeds humans**: `corr_noun_var` (4.81 writer vs 4.68 wp_stories) and `corr_adj_var` (3.15 journalist vs 2.87 wsj). → Qwen *over*-diversifies content words; it's lexically rich but not narratively complex.
6. **Stopword ratio** — hh_stories 0.495 highest, qwen roles ~0.41, wp_stories 0.466. Stories are stopword-heavy (`the/he/she/and/of`); qwen text is slightly *content-denser*.
7. **Length** — qwen produces ~400 tokens per item across all roles regardless; humans vary wildly (arxiv 155, wp_stories 613). Qwen is largely role-agnostic in length.
8. **Roles are nearly identical** across qwen_writer / qwen_journalist / qwen_advisor on *structural* features. → System role barely changes structure; it mainly changes vocabulary niche (see C).

---

## C. Lexical (log-likelihood) — which words appear in which pair

From [outputs_lexical_models/*.parquet](outputs_lexical_models/), top content-word shifts (LL > 15.13, p < 0.0001):

| comparison | over in HUMAN | over in QWEN |
|---|---|---|
| qwen_writer vs wp_stories | have, time, then, take, say | **silent, expression, scene, room, perhaps, moment, gaze, tension** |
| qwen_writer vs arxiv | time, show, energy, high | room, eye, face, stand, man, hand, moment, perhaps |
| qwen_journalist vs wsj | say, year, have, also | room, eye, face, light, stand, quiet, man, tension |
| qwen_journalist vs politics | make, year, say, include | face, moment, eye, man, light, hand, now, suggest |
| qwen_advisor vs wsj | say, day | stand, eye, face, hand, room, light, suggest, man |
| qwen_advisor vs politics | use | face, hand, suggest, eye, man, moment, now, light |

**Read this:** qwen invariably leans on a tight vocabulary of *embodied scene description* — `eye / face / hand / room / light / moment / gaze / tension / silent / suggest`. Across all 3 system roles. The role tag barely changes this. Humans, regardless of domain, use more *deictic / temporal / propositional* verbs: `say, have, year, make, time, then, take, show`.

> "qwen role" is essentially "qwen scene-describer with some vocab/domain-vocab knowledge". The role hint reshuffles (?) adjectives, not content type.

---




