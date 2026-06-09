# Claude Code Task — RAGpack v1.2 Colab Notebook (Interactive Workflow)

Work in the local repo at:
`<wherever Taka clones the pipeline locally>` — e.g.
`/Users/raskolnikoff/PycharmProjects/noesisnoema-pipeline`.
Repo: `rag-fish/noesisnoema-pipeline`. Branch off `main` (HEAD is the v1.2 merge,
PR #13 merged).

This is the **interactive Colab notebook companion** to the CLI `nn-pipeline build`
introduced in PR #13. It does NOT add new pipeline functionality — it provides a
notebook-driven UX for the same `run_pipeline_v12()` function that the CLI calls.
The CLI remains the canonical entry point; the notebook is for interactive,
visually-verifiable RAGpack generation runs (Taka's preferred workflow per
ADR-0011 §5 context).

## Background

After PR #13 merged, the pipeline produces v1.2 RAGpacks via:
- `cli/build_ragpack.py::run_pipeline_v12()` (importable Python function)
- `nn-pipeline build --embedder llama-cpp --gguf <path> ...` (CLI)

The notebook wraps the same `run_pipeline_v12()` call with surrounding cells
that:
1. Install dependencies in a Colab environment (`pip install`)
2. Either mount Google Drive or accept direct upload for the embedder GGUF
3. Accept source documents (.txt / .md only — the pipeline doesn't handle PDF
   directly; PDF→txt conversion is a separate, optional pre-cell)
4. Call `run_pipeline_v12()` and display each artifact as it lands
5. Zip the output directory and offer it for download / Drive save
6. Verify the GGUF SHA-256 fingerprint matches the NoesisNoema app expectation
   (`0c7930f6c4f6f29b7da5046e3a2c0832aa3f602db3de5760a95f0582dbd3d6e6` for the
   currently-shipping `nomic-embed-text-v1.5.Q5_K_M.gguf`)

The notebook also works locally in Jupyter / VS Code; Colab is the primary
target but nothing in the notebook is Colab-exclusive — Google Drive mounting
and Colab `files.upload()` are guarded by `try/except` so the notebook runs
on either platform.

## Scope

### N1. Notebook file

Create `notebooks/build_ragpack_v1_2.ipynb` (new directory if it doesn't exist).
The notebook MUST be valid JSON, executable top-to-bottom on a fresh Colab CPU
runtime (no GPU required for nomic-embed-text-v1.5 at the Spinoza-Ethica
scale). Use the standard nbformat (4.x).

Cell layout (in order):

#### Cell 1 — Markdown intro
- One-line statement: "RAGpack v1.2 builder for NoesisNoema (ADR-0011 §5)."
- Brief description: what this notebook does, what the output is, who consumes
  it (NoesisNoema v0.4+ app).
- Link to ADR-0011 in `rag-fish/RAGfish`.
- Important note: the embedder GGUF must be `nomic-embed-text-v1.5.Q5_K_M.gguf`
  (or a fingerprint-matching variant) to be importable by the current app build.

#### Cell 2 — Environment detection
```python
import sys
IS_COLAB = "google.colab" in sys.modules
print(f"Environment: {'Colab' if IS_COLAB else 'Local Jupyter'}")
print(f"Python: {sys.version.split()[0]}")
```

#### Cell 3 — Install dependencies
```python
# In Colab: install the pipeline from GitHub (main branch).
# Locally: assume the pipeline is already installed in the active env.
if IS_COLAB:
    !pip install -q git+https://github.com/rag-fish/noesisnoema-pipeline.git@main
    !pip install -q llama-cpp-python
else:
    print("Local mode — using the installed pipeline package "
          "(pip install -e . from the repo root).")
```

**Note**: the notebook installs `llama-cpp-python` separately in Colab because
the pipeline's `pyproject.toml` may not list it as a hard dependency for CI
reasons (verify by inspecting `pyproject.toml` / `requirements.txt`). If
`llama-cpp-python` is already pinned in the pipeline package, the second
`pip install` is a no-op idempotent step. Make sure both `pip install` lines
are clearly labelled as Colab-only.

#### Cell 4 — Obtain the embedder GGUF (Colab) / Specify path (local)

Provide three sub-paths in one markdown explanation, plus a single code cell
that handles all three:

```python
import os
from pathlib import Path

if IS_COLAB:
    # OPTION A: mount Drive (recommended for repeat runs)
    try:
        from google.colab import drive
        drive.mount("/content/drive")
        # Adjust the path below to wherever you keep the GGUF in your Drive:
        GGUF_PATH = Path("/content/drive/MyDrive/Models/nomic-embed-text-v1.5.Q5_K_M.gguf")
    except Exception:
        GGUF_PATH = None
    # OPTION B: direct upload (one-shot)
    if GGUF_PATH is None or not GGUF_PATH.is_file():
        from google.colab import files
        print("Drive path not found — please upload the GGUF directly:")
        uploaded = files.upload()  # opens a chooser; user picks the GGUF
        GGUF_PATH = Path("/content") / next(iter(uploaded.keys()))
else:
    # OPTION C: local path — adjust as needed
    GGUF_PATH = Path("/path/to/nomic-embed-text-v1.5.Q5_K_M.gguf")

assert GGUF_PATH.is_file(), f"GGUF not found at {GGUF_PATH}"
print(f"GGUF: {GGUF_PATH}  ({GGUF_PATH.stat().st_size / 1024**2:.1f} MB)")
```

#### Cell 5 — Verify GGUF SHA-256 fingerprint

Critical step (ADR-0011 §3 identity check):

```python
import hashlib

EXPECTED_FINGERPRINT = "0c7930f6c4f6f29b7da5046e3a2c0832aa3f602db3de5760a95f0582dbd3d6e6"

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

actual = sha256_file(GGUF_PATH)
print(f"SHA-256: {actual}")
print(f"Expected: {EXPECTED_FINGERPRINT}")
if actual == EXPECTED_FINGERPRINT:
    print("✅ Fingerprint matches the NoesisNoema app embedder.")
else:
    print("⚠️  Fingerprint does NOT match. The resulting pack will be rejected "
          "by NoesisNoema v0.4+ unless the app is rebuilt with this GGUF.")
```

The notebook MUST NOT halt on mismatch — the user may be deliberately building
a pack for a future / experimental embedder. Just print clearly.

#### Cell 6 — Obtain source documents

Markdown header: "Source documents (.txt / .md only)".

```python
INPUT_DIR = Path("/content/input") if IS_COLAB else Path("./input")
INPUT_DIR.mkdir(exist_ok=True)

if IS_COLAB:
    # Direct upload — user selects .txt/.md files.
    from google.colab import files
    print("Upload one or more .txt or .md files (PDF not directly supported; "
          "convert PDF → txt first if needed).")
    uploaded = files.upload()
    for name, data in uploaded.items():
        (INPUT_DIR / name).write_bytes(data)
else:
    print(f"Local mode — place .txt/.md files in {INPUT_DIR.resolve()} and "
          "re-run this cell to list them.")

source_files = sorted(p for p in INPUT_DIR.iterdir()
                      if p.is_file() and p.suffix.lower() in {".txt", ".md"})
print(f"\nSource files ({len(source_files)}):")
for p in source_files:
    print(f"  {p.name}  ({p.stat().st_size / 1024:.1f} KB)")

assert source_files, f"No .txt or .md files in {INPUT_DIR}"
```

#### Cell 6.5 — (Optional) PDF → txt pre-conversion

Provide as a separate, **optional** cell with markdown explaining "if you have
PDFs, run this; otherwise skip":

```python
# OPTIONAL: convert any .pdf files in INPUT_DIR to .txt next to them.
# Uses pypdf (lightweight, pure-Python). Adjust as needed.
def convert_pdfs_to_txt(directory: Path) -> int:
    try:
        from pypdf import PdfReader
    except ImportError:
        !pip install -q pypdf
        from pypdf import PdfReader
    pdfs = list(directory.glob("*.pdf"))
    for pdf_path in pdfs:
        reader = PdfReader(str(pdf_path))
        text = "\n\n".join((page.extract_text() or "") for page in reader.pages)
        out_path = pdf_path.with_suffix(".txt")
        out_path.write_text(text, encoding="utf-8")
        print(f"  {pdf_path.name} → {out_path.name}  ({len(text):,} chars)")
    return len(pdfs)

n = convert_pdfs_to_txt(INPUT_DIR)
print(f"Converted {n} PDF(s).")
```

After this cell, re-run Cell 6 to pick up the new .txt files.

#### Cell 7 — Configuration

```python
from datetime import datetime, timezone

OUTPUT_DIR = Path("/content/output") if IS_COLAB else Path("./output")
OUTPUT_DIR.mkdir(exist_ok=True)

CHUNK_SIZE    = 512    # tokens per chunk
OVERLAP       = 50     # token overlap between chunks
CREATION_TIME = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

print(f"chunk_size:    {CHUNK_SIZE}")
print(f"overlap:       {OVERLAP}")
print(f"creation_time: {CREATION_TIME}")
print(f"output_dir:    {OUTPUT_DIR}")
```

**Note**: `creation_time` is part of the deterministic `pack_id` derivation
(see `_derive_pack_id` in `cli/build_ragpack.py`). Using `datetime.now()` here
means the pack_id will change between runs unless the user pins
`CREATION_TIME` manually. Document this in a markdown cell preceding this cell.

#### Cell 8 — Build the pack

```python
from cli.build_ragpack import run_pipeline_v12

result = run_pipeline_v12(
    input_dir=INPUT_DIR,
    output_dir=OUTPUT_DIR,
    gguf_path=GGUF_PATH,
    chunk_size=CHUNK_SIZE,
    overlap=OVERLAP,
    creation_time=CREATION_TIME,
    verbose=True,
)

print(f"\n✅ Build complete.")
print(f"   files:  {result.file_count}")
print(f"   chunks: {result.chunk_count}")
print(f"   output: {result.output_dir}")
```

#### Cell 9 — Inspect manifest

```python
import json

with open(result.written_paths["manifest"]) as f:
    manifest = json.load(f)

print(json.dumps(manifest, indent=2, ensure_ascii=False))
```

Markdown commentary above this cell: explain that the user should visually
verify `pack_version == "1.2"`, `embedder.model_hash` matches the expected
fingerprint, `embedder.embedding_dimension == 768`, `embedder.pooling == "mean"`,
`embedder.l2_normalized == true`, etc.

#### Cell 10 — Inspect embeddings shape

```python
import numpy as np

arr = np.load(result.written_paths["embeddings"])
print(f"embeddings.npy shape: {arr.shape}")
print(f"dtype:                {arr.dtype}")
print(f"first row norm:       {np.linalg.norm(arr[0]):.6f}")
print(f"first 8 values:       {arr[0, :8]}")
```

Markdown above: "Verify shape is `(N, 768)`, dtype `float32`, first-row norm
≈ 1.0 (L2-normalized)."

#### Cell 11 — Inspect chunks + citations

```python
with open(result.written_paths["chunks"]) as f:
    chunks = json.load(f)

print(f"Total chunks: {len(chunks)}\n")
print("First chunk:")
print(json.dumps(chunks[0], indent=2, ensure_ascii=False)[:500])
print("…")

# Citations
print("\nFirst 3 citations:")
with open(result.written_paths["citations"]) as f:
    for i, line in enumerate(f):
        if i >= 3:
            break
        print(json.dumps(json.loads(line), indent=2, ensure_ascii=False)[:300])
        print("---")
```

#### Cell 12 — Zip + offer download

```python
import shutil

zip_base = OUTPUT_DIR.parent / OUTPUT_DIR.name
zip_path = Path(shutil.make_archive(str(zip_base), "zip", str(OUTPUT_DIR)))
print(f"✅ Zipped: {zip_path}  ({zip_path.stat().st_size / 1024**2:.2f} MB)")

if IS_COLAB:
    from google.colab import files
    files.download(str(zip_path))  # triggers browser download
    print("Downloading…")
else:
    print(f"Local mode — zip available at {zip_path.resolve()}")
```

#### Cell 13 — (Optional) Save to Drive

```python
if IS_COLAB:
    drive_out = Path("/content/drive/MyDrive/Ragpacks")
    drive_out.mkdir(parents=True, exist_ok=True)
    shutil.copy(zip_path, drive_out / zip_path.name)
    print(f"✅ Saved to Drive: {drive_out / zip_path.name}")
else:
    print("Local mode — Drive save skipped.")
```

#### Cell 14 — Markdown footer
- Reminder: import the zip into NoesisNoema via Settings ▸ Manage RAGpacks ▸
  Import .zip
- Troubleshooting: if the app rejects the pack, the alert message names the
  exact validation that failed (`embedderFingerprintMismatch` /
  `embeddingDimensionMismatch` / etc.) — adjust GGUF or rebuild app
- Pointer to the 5-question RAG verification UAT recorded in the ADR / past
  transcripts

### N2. README update

Add a short section to `README.md` (after the existing "Usage" / CLI section):

```markdown
### Interactive notebook (Colab or local Jupyter)

For an interactive build flow with step-by-step verification, see
`notebooks/build_ragpack_v1_2.ipynb`. Open it directly in Colab via:

[![Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/rag-fish/noesisnoema-pipeline/blob/main/notebooks/build_ragpack_v1_2.ipynb)

The notebook wraps `cli.build_ragpack.run_pipeline_v12()` with cells for
dependency install, GGUF fingerprint verification, source upload, and zip
download. It produces the same v1.2 RAGpack as the CLI.
```

### N3. .gitignore

If not already present, add a line to `.gitignore` to keep notebook checkpoint
clutter out:

```
notebooks/.ipynb_checkpoints/
```

### N4. Tests

No new automated tests required. The notebook calls the same `run_pipeline_v12()`
function already covered by `tests/test_cli_build_v1_2.py` and friends. If you
want a smoke test, add a notebook execution test using `nbclient` (optional,
not required):

```python
# tests/notebooks/test_build_ragpack_v1_2_notebook.py (optional)
import nbformat
from nbclient import NotebookClient

def test_notebook_parses():
    nb = nbformat.read("notebooks/build_ragpack_v1_2.ipynb", as_version=4)
    # Just parse + count cells; don't execute (Colab-specific cells would fail).
    assert len(nb.cells) >= 10
```

Skip if `nbclient` / `nbformat` aren't already pipeline dependencies.

## Scope (hard)

- Touch ONLY:
  - `notebooks/build_ragpack_v1_2.ipynb` (new)
  - `README.md` (small additive section)
  - `.gitignore` (one line, only if missing)
  - optional: a parse-only notebook smoke test under `tests/notebooks/`
- Do NOT touch:
  - any embedder / writer / chunker / manifest code (PR #13 finished it)
  - the CLI (it's the canonical entry; the notebook wraps it)
  - schemas
- No new dependencies in `pyproject.toml` / `requirements.txt` (the notebook
  uses pip-install-on-Colab patterns instead).

## Verification

Before opening the PR:
- Open the notebook in a clean Jupyter / VS Code session, confirm it parses
  (cells render, JSON valid). Don't need to fully execute end-to-end if you
  don't have the GGUF at hand — the structure correctness is enough.
- Confirm the `from cli.build_ragpack import run_pipeline_v12` import works
  after a fresh `pip install -e .` (it's tested by PR #13's tests already, but
  worth a sanity check).

## Commit + PR

Conventional commits, 2-3:
1. `feat(notebook): add Colab/Jupyter notebook for RAGpack v1.2 builds`
2. `docs(readme): link to the interactive notebook`
3. `chore: ignore notebook checkpoints` (only if .gitignore needed updating)

Push branch (suggested `feat/colab-notebook-v1.2`). Open PR to `main`:
**Title**: `feat(notebook): interactive RAGpack v1.2 builder (Colab + Jupyter)`

PR body MUST include:
- Reference to ADR-0011 (in `rag-fish/RAGfish`) and PR #13
- A cell-by-cell summary of what the notebook does
- The "Open in Colab" badge URL it adds to README
- Note: the notebook is a thin wrapper around `run_pipeline_v12()`, no
  pipeline logic changes
- Confirmation: GGUF fingerprint verification cell uses the same expected
  hash (`0c7930f6...`) as the app side
- Any orthogonal findings

Do NOT merge. Taka tests the notebook in Colab against the real Spinoza
Ethica PDF and merges if it produces an importable pack.

## Anti-goals

- Do NOT add new embedder backends, chunker options, or manifest fields.
- Do NOT make the notebook depend on a GPU runtime; CPU is sufficient.
- Do NOT inline llama.cpp build flags or quantisation logic — the notebook
  consumes a pre-built GGUF.
- Do NOT call `run_pipeline` (the legacy v1.1 path) from the notebook.
- Do NOT embed the actual GGUF or any other large binary in the notebook
  (the file would balloon and become un-git-friendly).
- Do NOT enable code execution from untrusted sources (no `!curl | bash`,
  no untrusted pip indexes).

## Report back

- Path to the new notebook + cell count + total size
- Confirmation that the notebook is valid JSON and parses with `nbformat.read`
- The expected behavior summary: what each cell does, in 1-2 lines
- Any orthogonal findings
- PR number
