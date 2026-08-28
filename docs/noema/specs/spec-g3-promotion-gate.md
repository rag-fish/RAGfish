# Spec: G3 Promotion Gate (pipeline, v0.8)

**Repo:** noesisnoema-pipeline (feature branch + PR, main is protected)
**Rule:** A RAGpack may move `candidate → promoted` only if gold-set Recall@k ≥ policy threshold, with a human approval stamp.

## CLI

```
noema-gate run   --pack <pack_dir> --goldset <goldset.jsonl> --policy <noema-policy.yaml> [--out <report.json>]
noema-gate stamp --pack <pack_dir> --report <report.json> --approved-by <id>
noema-gate verify --pack <pack_dir>
```

- `run`: executes retrieval against the pack exactly as the app would (same embedder, same mean-centering per manifest — reuse pipeline retrieval harness; do NOT re-implement geometry). Computes Recall@k. Exit code 0 iff value ≥ threshold. Writes `report.json`.
- `stamp`: writes `governance.promotion` block into the manifest (status=promoted, policy_sha256, eval_report_sha256, recall_at_k, approved_by, approved_at). Refuses if report failed or hashes mismatch. Emits audit events (see spec-audit-pipeline.md).
- `verify`: recomputes hashes, validates manifest against v1.3 schema, checks promotion block consistency. CI entrypoint.

## Gold-set format (JSONL)

```json
{"query_id": "q001", "query": "…", "relevant_chunk_ids": ["c_0412", "c_0413"]}
```

- Minimum 30 queries per corpus domain for a calibration-grade run; gate refuses (exit 2) below 10.
- `relevant_chunk_ids` reference chunk ids inside the pack; `run` fails fast on dangling ids.

## Metric

Recall@k = mean over queries of |retrieved_top_k ∩ relevant| / |relevant|. Default k=5, threshold 0.80 — **initial calibration values from policy manifest, not empirical claims**. Re-baseline after first three gated runs.

## Report schema (report.json)

```json
{
  "gate": "G3",
  "pack_id": "…",
  "policy_sha256": "…",
  "goldset_sha256": "…",
  "k": 5,
  "threshold": 0.80,
  "recall_at_k": 0.87,
  "per_query": [{"query_id": "q001", "hit": 2, "relevant": 2}],
  "embedder_id": "nomic-embed-text-v1.5",
  "normalization": "mean_center",
  "ran_at": "2026-07-02T10:00:00+09:00"
}
```

## Failure modes to test

1. Threshold boundary (value == threshold passes; value = threshold − ε fails).
2. Manifest/embeddings hash mismatch → `stamp` refuses.
3. Gold-set with dangling chunk ids → `run` exits 2 with the offending ids listed.
4. Policy file edited between `run` and `stamp` (policy_sha256 mismatch) → `stamp` refuses.
5. Re-stamping an already-promoted pack → refuses without `--force`, which itself emits a distinct audit event.

## Report preservation (amended 2026-07-14)

`noema-gate run` writes its report to a standard tracked location by default:
`reports/g3/<pack_id>/<UTC-timestamp>-report.json`. `--out` may override;
existing files are never silently overwritten (refuse, no `--force` for `run`).

`noema-gate stamp` refuses if the report file is not tracked by git in the
repository containing it (dangling-evidence prevention). Escape hatch
`--allow-untracked-report` exists but emits a distinct audit event recording
the override.

The `gate.run` audit event's `outputs.sha256_refs` MUST include the report hash.

## Non-goals (v0.8)

- Precision / faithfulness / answer-quality metrics.
- Automatic gold-set generation (manual curation; LLM-assisted drafting allowed but human-reviewed).
