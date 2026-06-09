# Claude Code Task — Pipeline v1.2: llama.cpp Embedder + RAGpack v1.2 Spec (ADR-0011 §5)

Work in the local repo at:
`<wherever Taka clones the pipeline locally>` — recommend
`/Users/raskolnikoff/Workspace/noesisnoema-pipeline` or similar.
Repo: `rag-fish/noesisnoema-pipeline`. Branch off `main` (HEAD `28e62f6`).

This is **the pipeline-side counterpart** to ADR-0011 PR-A (#97) and PR-B (#98) on
the `rag-fish/NoesisNoema` app side. Both PRs are already merged. NoesisNoema
currently rejects every RAGpack import because the app expects v1.2 manifests
produced by an llama.cpp-based embedder, but the pipeline still produces v1.1
manifests from `sentence-transformers/all-MiniLM-L6-v2`. This PR closes that gap.

After this PR merges and the Spinoza Ethica pack is regenerated, RAG works
end-to-end.

## Background — what the app expects (from ADR-0011 §3 + PR #98)

The app's v1.2 reader validates each imported manifest with these specific checks:

- `pack_version == "1.2"` (exact string)
- `embedder.dtype == "float32"` (exact string)
- `embedder.pooling == "mean"` (exact string)
- `embedder.l2_normalized == true`
- `embedder.embedding_dimension == <current app embedder dimension>`
- `embedder.model_hash == <SHA-256 hex of the embedder GGUF FILE BYTES>`
  (case-insensitive hex compare)

For the embedder GGUF currently shipping in the app
(`nomic-embed-text-v1.5.Q5_K_M.gguf`), the expected fingerprint is exactly:

```
0c7930f6c4f6f29b7da5046e3a2c0832aa3f602db3de5760a95f0582dbd3d6e6
```

The pipeline MUST produce manifests where `model_hash` equals this string for any
RAGpack intended to be imported by the current app build. This is the central
identity check from ADR-0011 §3.

## Current pipeline state (verified at HEAD 28e62f6)

- `embedder/deterministic_embedder.py` — `DeterministicEmbedder` class wrapping
  `sentence-transformers/all-MiniLM-L6-v2`. Default model name pinned via
  `DEFAULT_MODEL_NAME`. `EmbedderMetadata.model_hash` computed from a **JSON
  config dict** (not the model file bytes) — this is the wrong identity for app
  interop and MUST change.
- `ragpack/manifest_builder.py` — builds manifest dict per
  `schemas/manifest_v1_1.json`.
- `schemas/manifest_v1_1.json` — v1.1 schema; embedder block does not require
  `pooling` or `l2_normalized` fields, and `dtype` was free-form.
- `chunker/token_chunker.py` — produces `chunk_text_with_offsets` records with
  `paragraph_boundaries`, `doc_id`, `char_start`, `char_end`, etc. The app side
  reader (PR #98) expects citations in `citations.jsonl` keyed by
  `{"chunk_index": N, "doc_id": ..., "page": ..., "char_start": ...,
   "char_end": ..., "paragraph_boundaries": [...]}`.

## Scope of this PR

### P1. New llama.cpp-based embedder

Create `embedder/llamacpp_embedder.py` as a new module. Public surface should
mirror the existing `DeterministicEmbedder` API so callers (notebook + CLI) need
minimal changes:

```python
class LlamaCppEmbedder:
    def __init__(self, gguf_path: str): ...
    @property
    def metadata(self) -> EmbedderMetadata: ...
    def embed_chunks(self, chunks: Sequence[ChunkRecord]) -> EmbeddingResult: ...
    def embed_texts(self, texts: Sequence[str]) -> np.ndarray: ...
```

Implementation requirements:

- Use `llama-cpp-python` (add to `requirements.txt` / `pyproject.toml`). Embedding
  mode is enabled by passing `embedding=True` to `Llama(...)` constructor.
- Load model with: `Llama(model_path=gguf_path, embedding=True, n_ctx=8192,
  n_batch=8192, n_ubatch=8192, pooling_type=LLAMA_POOLING_TYPE_MEAN, verbose=False)`.
  Use `llama_cpp.llama_pooling_type` enum or the equivalent string constant the
  bindings expose; if the bindings don't expose pooling configuration directly,
  document it in code comments and verify mean-pooled output via the
  `Llama.create_embedding` API which returns the pooled embedding by default.
- **Task prefix MUST be applied**: `nomic-embed-text-v1.5` requires
  `"search_document: "` for document/chunk texts (and `"search_query: "` for
  queries, but pipeline only embeds documents). Apply the prefix INSIDE
  `embed_chunks` and `embed_texts`, before passing to the model. Document this in
  the docstring so future maintainers don't strip it.
- **L2 normalize the output vectors** explicitly (don't rely on the model
  normalizing internally — the app side does explicit L2 normalize and the two
  must match). Use `np.linalg.norm(v) > 0` check; raise `ValueError` on zero norm
  (mirrors app's `EmbeddingError.zeroNorm` — visible failure, ADR-0000 §4).
- Output dtype: `float32` always.
- Output shape: `(N, 768)` for `nomic-embed-text-v1.5`.
- Determinism: `llama-cpp-python` is deterministic for embedding mode given the
  same input + same model + same flags. No RNG controls needed beyond pinning
  `seed=0` if the constructor accepts it.

### P2. EmbedderMetadata: change model_hash to GGUF file hash

The existing `EmbedderMetadata` in `embedder/deterministic_embedder.py` defines
`model_hash` as SHA-256 of a JSON config dict. **For app interop, `model_hash` MUST
be the SHA-256 of the GGUF file bytes.** Two options:

**Option (a) [preferred]**: keep the dataclass shared between embedders, change
its semantics, and document the change. Add a helper:

```python
def _sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()
```

The `LlamaCppEmbedder.__init__` computes `model_hash = _sha256_file(gguf_path)` at
load time and stores it in metadata.

The `DeterministicEmbedder` (sentence-transformers path) cannot meaningfully
compute a single file hash (it's a multi-file HuggingFace download). Either
(i) deprecate `DeterministicEmbedder` in this PR, or (ii) document that its
`model_hash` is config-based and explicitly NOT compatible with v1.2 manifests
intended for NoesisNoema app v0.4+. Recommended: deprecate it loudly in this PR
(warn on import), remove in a follow-up.

**Option (b)**: introduce a separate `LlamaCppEmbedderMetadata` dataclass. More
code, cleaner separation, but the manifest builder would need to handle both
shapes. Don't do this unless option (a) creates an unsolvable issue.

Pick (a) by default; document the choice in the PR body.

### P3. New manifest schema: v1.2

Create `schemas/manifest_v1_2.json`. Lift the v1.1 schema (`schemas/manifest_v1_1.json`)
to v1.2 with the following deltas:

- `pack_version.const = "1.2"`
- `embedder.required` ← add `"pooling"` and `"l2_normalized"`
- `embedder.properties.pooling.enum = ["mean"]` (v1.2 only supports mean pooling;
  if we add cls/max later, bump to v1.3)
- `embedder.properties.l2_normalized.type = "boolean"`
- `embedder.properties.l2_normalized.const = true` (v1.2 requires L2-normalized
  embeddings)
- `embedder.properties.dtype.enum = ["float32"]` (v1.2 requires float32; was
  free-form string in v1.1)
- `embedder.properties.runtime` (optional): `"type": "string"`,
  `"description": "Embedding runtime identifier, e.g. 'llama.cpp'"`
- `embedder.required` keeps `model_hash` (it was already required in v1.1; semantics
  change is documented in P2 above).
- Everything else stays the same as v1.1.

Keep `schemas/manifest_v1_1.json` untouched (for backward compatibility / archival
reference).

### P4. ManifestBuilder + PackWriter: emit v1.2

Update `ragpack/manifest_builder.py`:

- Add a new entry point or kwarg to build v1.2 manifests. Recommend keeping a
  `pack_version` kwarg that defaults to `"1.2"`; for callers explicitly building
  v1.1, accept `"1.1"` and emit the v1.1 shape. Default is v1.2.
- When `pack_version == "1.2"`, include `embedder.pooling`, `embedder.l2_normalized`,
  and optionally `embedder.runtime` in the manifest body.
- The canonical manifest hash (`_manifest_hash`) computation rules don't change.

Update wherever `PackWriter` / pack-build orchestration constructs the manifest
to feed in the new fields from `EmbedderMetadata` and pass `pack_version="1.2"`
by default.

### P5. CLI default: switch to v1.2 + llama.cpp embedder

If the repo has a `nn-pack` CLI (`ragpack/cli.py` or similar — locate it), update
the default flow so:

- The CLI accepts a `--embedder llama-cpp --gguf <path>` mode and treats it as the
  default for v1.2 output.
- The legacy `--embedder sentence-transformers` (or implicit) mode is retained
  but emits a deprecation warning saying "produces v1.1 manifests, not compatible
  with NoesisNoema v0.4+".
- The default `pack_version` written to disk is `"1.2"`.
- A `--gguf` argument or `NOESIS_EMBEDDER_GGUF` env var locates the embedder
  GGUF; require it for v1.2 builds.

### P6. Citations: confirm shape matches app expectations

Verify `chunker/token_chunker.chunk_text_with_offsets` output, when serialised to
`citations.jsonl`, has the shape the app's RAGpackReader expects (PR #98 spec):

```json
{"chunk_index": 0, "doc_id": "...", "page": 12, "char_start": 100,
 "char_end": 612, "paragraph_boundaries": [0, 87, 234, 612]}
```

- `chunk_index` is the row index matching the `embeddings.npy` row.
- `doc_id` is the source document identifier (currently `"unknown"` if not set —
  consider requiring or defaulting to source filename for the v1.2 build).
- `page` (optional, integer) — only meaningful for PDF chunks.
- `char_start` / `char_end` — character offsets within the source document.
- `paragraph_boundaries` — list of integer offsets.

If the chunker output uses different field names (e.g. `start_offset` vs
`char_start`), normalize the keys at `citations.jsonl` serialization time to
match the spec above. The app's reader is strict about field names.

### P7. Tests

Update / add tests:

- `tests/embedder/test_llamacpp_embedder.py` (new):
  - smoke test: load `nomic-embed-text-v1.5.Q5_K_M.gguf` (path supplied via env
    var; skip test if not present in CI), embed `"hello world"`, assert shape ==
    (1, 768) and norm ≈ 1.0
  - determinism test: embed the same text twice, assert byte-identical output
  - metadata test: assert `metadata.model_hash` matches the SHA-256 of the GGUF
    file bytes
- `tests/ragpack/test_manifest_builder.py`: add v1.2 case, asserting the v1.2
  manifest has `pack_version="1.2"`, `embedder.pooling="mean"`,
  `embedder.l2_normalized=true`, `embedder.dtype="float32"`.
- `tests/schemas/test_manifest_v1_2.py`: validate a built v1.2 manifest against
  `schemas/manifest_v1_2.json`.
- If there's an end-to-end pack-build test, add a v1.2 variant.

### P8. Documentation

- Update `README.md`: replace the "## [1.1] - 2025-08" block with a "## [1.2]"
  block listing the embedder switch, schema delta, and the GGUF fingerprint
  identity model.
- Add a short migration note: existing v1.1 packs are not consumable by
  NoesisNoema v0.4+; regenerate with the v1.2 CLI.

## Scope (hard)

- Touch ONLY:
  - `embedder/llamacpp_embedder.py` (new)
  - `embedder/__init__.py` (export the new class; add deprecation warning on the
    old import path if going option (a) from P2)
  - `embedder/deterministic_embedder.py` (deprecation warning + the
    `_sha256_file` helper if it lives here)
  - `schemas/manifest_v1_2.json` (new)
  - `ragpack/manifest_builder.py` (v1.2 emission)
  - `ragpack/cli.py` or whichever file holds the CLI entry point (v1.2 default)
  - `requirements.txt` / `pyproject.toml` (add `llama-cpp-python`)
  - tests under `tests/`
  - `README.md`
- Do NOT touch:
  - `chunker/` core logic (only adjust citation serialization keys if needed)
  - `schemas/manifest_v1_1.json` (preserve as-is for archival)
  - notebook (`gguf_downloader_colab.ipynb`) — out of scope
  - Hugging Face download helpers — orthogonal

## Build / test verification

Before opening the PR:
- `pip install -e .` (or equivalent) succeeds in a clean venv
- The pipeline can produce a v1.2 RAGpack end-to-end from a test document, given
  the GGUF path
- New tests pass (`pytest tests/embedder/test_llamacpp_embedder.py`,
  `pytest tests/ragpack/test_manifest_builder.py`, etc.)
- Old tests still pass (`pytest`)
- `python -c "import noesisnoema_pipeline"` (or equivalent) imports without errors
  / with only documented deprecation warnings

## Commit + PR

Conventional commits — 3-5 commits acceptable, e.g.:
1. `feat(embedder): add LlamaCppEmbedder (nomic-embed-text-v1.5)`
2. `feat(schema): add manifest v1.2 schema`
3. `feat(ragpack): emit v1.2 manifests with pooling + l2_normalized + file-hash identity`
4. `feat(cli): default to v1.2 + llama-cpp embedder; deprecate v1.1 path`
5. `docs: update README for v1.2; add migration note`

Push branch (suggested name `feat/ragpack-v12-llamacpp-embedder`). Open PR to
`main`:
**Title**: `feat: RAGpack v1.2 + llama.cpp embedder (NoesisNoema app interop)`

PR body MUST include:
- Reference to ADR-0011 (in `rag-fish/RAGfish`) and app-side PRs #97 / #98
- The v1.2 schema delta vs v1.1
- Confirmation: SHA-256 of the test GGUF used in tests, and confirmation that
  this matches the app's expected fingerprint
  (`0c7930f6c4f6f29b7da5046e3a2c0832aa3f602db3de5760a95f0582dbd3d6e6`) when the
  same GGUF (`nomic-embed-text-v1.5.Q5_K_M.gguf`) is the input.
- Verification: a small end-to-end "build a 3-chunk v1.2 pack" demo + manifest
  output paste (show the actual JSON the pipeline writes)
- Deprecation note for v1.1 path
- Any orthogonal findings noted but not fixed

Do NOT merge — Taka merges after re-generating the Spinoza Ethica pack and
running it through NoesisNoema for the 5-question UAT.

## Anti-goals

- Do NOT remove `DeterministicEmbedder` entirely in this PR (deprecate only —
  removal in a separate cleanup PR after the v1.2 transition is verified).
- Do NOT modify chunker logic (token_chunker.py) — only citation serialization
  keys if shape mismatches the app spec.
- Do NOT modify the notebook (Colab interop is orthogonal; if it needs an update,
  do it in a follow-up).
- Do NOT support both v1.1 and v1.2 as equal first-class outputs — v1.2 is the
  default; v1.1 is deprecation-warned legacy.
- Do NOT introduce sentence-transformers as a llama.cpp adapter shim. The two
  paths are fully independent.

## Report back

- The diff per file (file list + per-file size of change)
- New test results (paste pytest output)
- Output of computing SHA-256 of `nomic-embed-text-v1.5.Q5_K_M.gguf` from the
  llama.cpp embedder — confirm match with
  `0c7930f6c4f6f29b7da5046e3a2c0832aa3f602db3de5760a95f0582dbd3d6e6`
- A sample v1.2 manifest JSON the pipeline now produces (paste in PR body)
- Any orthogonal findings
- PR number
