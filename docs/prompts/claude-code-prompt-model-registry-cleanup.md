# Claude Code Task — Model Registry & Default Model Cleanup

Work in the local repo at:
`/Users/raskolnikoff/Xcode Projects/NoesisNoema`
Repo: `rag-fish/NoesisNoema`. Branch off `main` (HEAD `4f49966`, PR #95 merged).

## Background

ADR-0011 just landed: NoesisNoema is moving its embedder to llama.cpp + a replaceable GGUF.
Before that implementation begins, the model layer needs cleanup. Investigation
revealed accumulated drift in `Apps/macOS/NoesisNoema/ModelRegistry/Core/ModelRegistry.swift`
and `Shared/Llama/LlamaState.swift`:

- 6 LLMs are declared in `predefinedSpecs`, but only 1 (Llama 3.2 3B) is the chosen
  default and used in practice.
- 3 of the 6 declarations point at GGUF filenames that DO NOT EXIST in
  `Apps/macOS/NoesisNoema/Resources/Models/` (`llama3-8b.gguf`, `phi-3-mini.gguf`,
  `gemma-2b.gguf`) — pure ghost entries.
- The other 2 (Jan-V1-4B, gpt-oss-20b) point at GGUFs that Taka is intentionally
  retiring.
- `LlamaState.swift:48` hard-codes `let primaryFile = "llama3-8b.gguf"` for macOS
  (file doesn't exist) and falls back to Jan-v1; the iOS branch uses
  `"Llama-3.2-3B-Instruct-Q4_K_M.gguf"` (correct) but the physical file on disk is
  `llama-3.2-3b-instruct-q4_k_m.gguf` (lowercase) — a latent case-sensitivity bug
  for iOS device builds.
- `LlamaState.swift:388` comment mentions Jan-v1-4B in a watchdog comment.

Bundled GGUFs currently on disk (verified by Xcode screenshot):
- `llama-3.2-3b-instruct-q4_k_m.gguf` ← KEEP (current default; rename for case consistency)
- `Jan-v1-4B-Q4_K_M.gguf` ← Taka will delete from disk
- `gpt-oss-20b-F16.gguf` ← Taka will delete from disk (40GB; caused yesterday's GPU pegging)
- `Llama-3.3-70B-Instruct-UD-IQ1_S.gguf` ← Taka will delete from disk

## Decision (Taka's)

- KEEP only Llama 3.2 3B as the registered/declared LLM.
- REMOVE all other LLM declarations from `predefinedSpecs`: Jan-V1-4B, Llama-3 (8B),
  Phi-3-mini, Gemma 2B, gpt-oss-20b.
- FIX the LlamaState.swift hard-coded defaults so macOS and iOS both point at
  Llama 3.2 3B (the one model that actually ships).
- FIX the GGUF filename case so registry and physical file match
  (`llama-3.2-3b-instruct-q4_k_m.gguf`, all-lowercase, mirroring the existing
  on-disk file — safer than renaming the file, since iOS Simulator and device are
  case-sensitive).
- DO NOT delete the actual `.gguf` files from the repo (they're git-ignored anyway).
  Taka deletes the disk files manually after this PR lands.

## Tasks

1. Branch `chore/registry-cleanup-llama32-only` off `main`.

2. **`Apps/macOS/NoesisNoema/ModelRegistry/Core/ModelRegistry.swift`**:
   - Inside `predefinedSpecs` (currently 6 entries), KEEP only the first (Llama 3.2 3B).
   - REMOVE the entries for Jan-V1-4B, Llama-3 (8B), Phi-3-mini, Gemma 2B, gpt-oss-20b.
   - Update the kept Llama 3.2 3B entry's `modelFile` to
     `llama-3.2-3b-instruct-q4_k_m.gguf` (all-lowercase) so it matches the on-disk
     filename. Confirm the `id` and `displayName` are consistent.
   - If `predefinedSpecs` has a doc comment naming the removed models, update it.
   - Any helper / lookup methods that reference the removed model IDs by string
     literal (search for `"Jan-v1-4B"`, `"Llama-3"`, `"phi-3-mini"`, `"gemma-2b"`,
     `"gpt-oss-20b"`) — remove or refactor as appropriate. If they're only used by
     tests or CLI scaffolding that's now dead, delete the dead code too (scope this
     to ModelRegistry; don't go on a wider cleanup).

3. **`Shared/Llama/LlamaState.swift`**:
   - Around line 47–53, the `defaultModelUrl` block currently has:
     ```swift
     #if os(macOS)
     let primaryFile = "llama3-8b.gguf"
     let secondaryFile = "Jan-v1-4B-Q4_K_M.gguf"
     #else
     let primaryFile = "Llama-3.2-3B-Instruct-Q4_K_M.gguf"
     let secondaryFile = "Jan-v1-4B-Q4_K_M.gguf"
     #endif
     ```
     Replace BOTH branches with a single declaration (no `#if` needed since only one
     model ships):
     ```swift
     let primaryFile = "llama-3.2-3b-instruct-q4_k_m.gguf"
     ```
     Remove the `secondaryFile` variable entirely along with its usage below
     (`if let url = findInBundle(secondaryFile) { return url }`). Also remove the
     stale comment `// プラットフォーム優先: iOSはJan、macOSはLlama3-8B`.
   - The "旧フォールバック" line at the bottom of `defaultModelUrl` returning
     `Bundle.main.url(forResource: "ggml-model", ...)`: REMOVE it too. With only one
     model, the file either resolves or we return nil; no silent fallback (ADR-0000).
   - Line 388 comment: `// First-token watchdog: strict deadline for Jan-v1-4B (8s), relaxed for larger models (15s)`
     → reword to remove the Jan-v1 reference. Suggest:
     `// First-token watchdog: strict deadline for the on-device model (8s)`.
     The `FIRST_TOKEN_DEADLINE_S: Double = 8.0` line stays unchanged.

4. **Tests / CLI / examples that reference removed models** (under
   `Apps/macOS/NoesisNoema/Tests/ModelRegistryTests/`,
   `Apps/macOS/NoesisNoema/ModelRegistry/CLI/`, `Apps/CLI/LlamaBridgeTest/`):
   Grep for the removed model IDs and update or delete the references. For tests
   that assert "registry contains gpt-oss-20b" etc., delete those test cases (they
   were asserting the ghost state). If a test asserts "registry contains
   Llama 3.2 3B" — keep and update its `modelFile` expectation to the lowercase name.
   Don't expand the test surface; just fix what breaks.

5. Grep self-check after edits:
   ```
   grep -rn "Jan-v1\|Jan-V1\|jan-v1\|llama3-8b\|phi-3-mini\|gemma-2b\|gpt-oss\|gpt_oss\|Llama-3.3-70B\|Llama-3.3-70b" --include="*.swift" .
   ```
   Should return ZERO matches in non-test Swift code. Tests-only matches that
   assert "this model is NOT in registry" are acceptable; otherwise no matches.

6. Build matrix — all four must remain green (SERIAL iOS builds; recurring lesson):
   - macOS Debug
   - macOS Release
   - iOS Simulator arm64 Debug
   - iOS Simulator arm64 Release (use `ARCHS=arm64 ONLY_ACTIVE_ARCH=NO`)
   No new warnings.

7. Conventional commit:
   `chore(models): remove ghost LLM registrations; default to Llama 3.2 3B only`
   Push. Open PR to `main`:
   `chore(models): registry cleanup — Llama 3.2 3B as sole declared model`
   PR body must include:
   - The accumulated drift summary (6 declared, 4 physical on disk, 3 ghosts, 2 retired)
   - The case-sensitivity fix for the GGUF filename
   - The LlamaState hard-coded-default removal
   - Removed ghosts: Jan-V1-4B, Llama-3 (8B), Phi-3-mini, Gemma 2B, gpt-oss-20b
   - Grep self-check output (zero non-test matches)
   - Build matrix (all 4 green)
   - Note: this prepares the ground for ADR-0011 (replaceable GGUF embedder) — the
     embedder GGUF will arrive in a subsequent PR; this PR does NOT add it.
   - Note: Taka will manually delete the 3 retired GGUFs from
     `Apps/macOS/NoesisNoema/Resources/Models/` on disk after this PR lands; no
     `.gguf` files are tracked in git so no repo change is needed for that.
   Do NOT merge.

## Scope (hard)

- ModelRegistry.swift + LlamaState.swift + immediately-broken tests/CLI.
- Do NOT touch: ADR docs, view layer, coordinator, executor, embedder code,
  DocumentManager, project.pbxproj (the synced folder convention handles file
  membership automatically), or the embedder design (that's ADR-0011, separate PR).
- Pure Swift; no new dependencies.
- If `LlamaState.swift` references `Jan-v1` in places I missed, treat each on its
  merit: pure dead comments → remove; live config → simplify to Llama 3.2 3B only.
- If you discover other dead model references beyond the listed names, note them
  in the PR body but DON'T fix them in this PR.

## Report back

- The exact diff per file.
- Grep self-check output.
- Build matrix (all 4 green).
- Any other dead model references noted but not fixed (for follow-up).
- PR number.

## Anti-goals

- Do NOT add the embedder GGUF here — that's ADR-0011 implementation, separate PR.
- Do NOT delete files from `Resources/Models/` via code; Taka handles disk cleanup.
- Do NOT change the LLM model itself; Llama 3.2 3B stays.
- Do NOT touch chat templates, sessions, retrieval, or any other subsystem.
