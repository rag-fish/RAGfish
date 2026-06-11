# Claude Code Task — NoesisNoema hotfix #3: exclude embedder GGUF from LLM registry

Local repo: `/Users/raskolnikoff/Xcode Projects/NoesisNoema`. Branch off `main` (PR #100 just merged).

## Bug (UAT blocker, the final layer)

After PR #99 + #100 unblocked RAGpack import, Spinoza chat returned **the same `[unusedN]` token sequence to all 5 questions** — different prompts, byte-identical garbage output. The Settings screen revealed the culprit: `Current Model: Nomic Embed Text V1.5.Q5 K M`. The embedder is being used as the chat LLM. `nomic-embed-text-v1.5` is an embedding-only model; asked to *generate*, it emits the BERT-family `[unused1]…[unused99]` reserved-vocab tokens because no actual generation head was trained.

## Root cause: registry scan registers ALL .gguf files indiscriminately

`Apps/macOS/NoesisNoema/ModelRegistry/Core/ModelRegistry.swift::scanDirectory` accepts any file with the `.gguf` extension and adds it to `modelSpecs` via `registerGGUFFile`. This was fine when only generator GGUFs lived in `Resources/Models/` (the PR #96 registry cleanup made `predefinedSpecs` correctly contain only Llama 3.2 3B), but PR #97 placed the embedder GGUF in the same directory. The scan picked it up; `availableModels` started exposing it; the LLM picker offered it; either Taka selected it once or UserDefaults restored a stale selection — either way, every chat now drives the embedder.

This is the same shape of prompt contract gap that caused PR #99 / #100: my registry-cleanup prompt scrubbed `predefinedSpecs` but did **not** add a scan-time embedder exclusion. CLI was faithful to the prompt; the prompt was incomplete.

## Fix policy (defense in depth — three layers)

### Layer 1: ModelRegistry.registerGGUFFile rejects embedding models

In `Apps/macOS/NoesisNoema/ModelRegistry/Core/ModelRegistry.swift`, after `GGUFReader.readMetadata` succeeds, decide whether this file is an **embedding model** and, if so, log + return WITHOUT registering. Detection heuristic (any one is sufficient):

1. **File-name signal**: the base name (lowercase) contains any of `"embed"`, `"-bert"`, `"jina-"`. Cheap, runs first, catches every embedder Anthropic / Nomic / Jina / BGE / E5 ships today.
2. **GGUF metadata `architecture` signal**: lowercase value contains `"bert"` (covers `bert`, `nomic-bert`, `jina-bert`, `mpnet-bert`, etc.). Use whatever field `GGUFMetadata.architecture` already exposes — don't add new GGUFReader parsing in this PR.
3. **GGUF metadata `pooling` signal** (optional, only if `GGUFMetadata` already surfaces it): non-nil pooling-type metadata is an embedding-model marker (generators never set it). If `GGUFMetadata` does NOT currently expose a pooling field, **do NOT add one in this PR** — the file-name + architecture signals are sufficient. Note it as an orthogonal finding.

The check goes inside `registerGGUFFile(at:)`, right after `try await GGUFReader.readMetadata`, before the `if let existingSpec = modelSpecs[id]` branch:

```swift
if Self.looksLikeEmbedder(fileName: fileName, metadata: metadata) {
    print("[ModelRegistry] Skipping embedder GGUF (not a generator): \(fileName)")
    return
}
```

Where `looksLikeEmbedder` is a new `static` helper on `ModelRegistry`:

```swift
static func looksLikeEmbedder(fileName: String, metadata: GGUFMetadata) -> Bool {
    let lower = fileName.lowercased()
    if lower.contains("embed") || lower.contains("-bert") || lower.contains("jina-") {
        return true
    }
    if metadata.architecture.lowercased().contains("bert") {
        return true
    }
    return false
}
```

Pure, deterministic, easily unit-testable. No new dependencies.

### Layer 2: ModelManager.setDefaultModel rejects embedder restoration

In `Shared/ModelManager.swift::setDefaultModel`, the UserDefaults restore path currently checks only that the saved ID still exists in `availableModels`. After Layer 1, embedders won't be in `availableModels`, so the existing `contains(where:)` check will already reject a stale `lastSelectedModelID` pointing at an embedder — BUT we still need to **clear the UserDefaults entry** in that case (otherwise the warning log will print on every launch). Update the branch:

```swift
if let lastModelIDString = UserDefaults.standard.string(forKey: "lastSelectedModelID") {
    if availableModels.contains(where: { $0.id == lastModelIDString }) {
        // existing restore path — unchanged
    } else {
        // ID is stale (e.g. embedder we no longer expose) — clear it and fall through
        UserDefaults.standard.removeObject(forKey: "lastSelectedModelID")
        SystemLog().logEvent(event: "[ModelManager] Cleared stale lastSelectedModelID: \(lastModelIDString)")
    }
}
// (Then the existing fallback path runs as today.)
```

Don't restructure the function further; this is a minimal additive guard.

### Layer 3: Sanity check before LLM dispatch (cheap belt-and-braces)

In `Shared/ModelManager.swift::generateAsyncAnswer`, right before calling `currentModel.generateAsync(...)`, log a warning if `currentLLMModel.modelFile.lowercased().contains("embed")`. Pure logging — do not throw or return early. This catches future surprise paths (e.g. someone calls `switchLLMModel("nomic-embed-text-v1.5")` directly) without breaking anything.

```swift
if currentModel.modelFile.lowercased().contains("embed") {
    _log.logEvent(event: "[ModelManager] WARN: currentLLMModel.modelFile looks like an embedder: \(currentModel.modelFile)")
}
```

## Acceptance

- Unit test for `ModelRegistry.looksLikeEmbedder` covering at least:
  - `("nomic-embed-text-v1.5.Q5_K_M.gguf", architecture: "nomic-bert")` → `true`
  - `("Llama-3.2-3B-Instruct-Q4_K_M.gguf", architecture: "llama")` → `false`
  - `("bge-large-en-v1.5.gguf", architecture: "bert")` → `true`
  - `("jina-embeddings-v2.gguf", architecture: "jina-bert")` → `true`
  - Empty/edge cases as you see fit.
- A short `#if DEBUG` smoke at app startup OR inside `ModelRegistry` (matching the PR #99 / #100 pattern) that asserts `availableModels` after `scanForModels()` does NOT contain any spec whose `modelFile` looks like an embedder. Document its output in the PR body.
- All 4 builds green (serial iOS; Release with `ARCHS=arm64 ONLY_ACTIVE_ARCH=NO`).

## Scope (hard)

- Touch ONLY:
  - `Apps/macOS/NoesisNoema/ModelRegistry/Core/ModelRegistry.swift` (the `looksLikeEmbedder` helper + the early-return in `registerGGUFFile`)
  - `Shared/ModelManager.swift` (UserDefaults cleanup branch + dispatch warning log)
  - A new test file under `Apps/macOS/NoesisNoema/ModelRegistry/Tests/` for `looksLikeEmbedder`
- Do NOT touch:
  - `ModelSpec.swift`, `ModelFactory.swift`, `GGUFReader.swift`, `Shared/RAG/*` (PR #99 + #100 just stabilized them), `Shared/Llama/*`, UI, `project.pbxproj`.
- Pure Swift; no new dependencies.

## Commit + PR

Single commit acceptable. Branch suggestion: `fix/registry-exclude-embedder`.
PR title: `fix(registry): exclude embedder GGUF from LLM selection (UAT blocker)`

PR body MUST include:
- The Spinoza chat screenshot's symptom (5x identical [unused] output)
- The 2-line code reference that registered the embedder
- The three-layer fix summary
- The `looksLikeEmbedder` table of test cases + results
- 4-build matrix
- Any orthogonal findings noted but not fixed

Do NOT merge — Taka merges, re-launches the app (UserDefaults cleanup runs once), re-imports the EXISTING Spinoza zip if needed (it should already be loaded), and continues UAT.

## Orthogonal (report only, do NOT fix)

- If `GGUFMetadata` does NOT currently surface a pooling-type field, note it — adding such surfacing in `GGUFReader` would let Layer 1 detect future embedders that don't match the file-name / architecture heuristics. Out of scope here.
- If the iOS bundle also ships the embedder GGUF and the registry runs on iOS too, confirm the same Layer 1 fix applies on iOS (it should, since `ModelRegistry.swift` is shared across platforms). If you find platform-specific scan paths that bypass `registerGGUFFile`, flag them.

## Report back

- Diff per file (file list + per-file size of change)
- Test output for `looksLikeEmbedder` (paste the table)
- Smoke output confirming `availableModels` excludes the embedder
- 4-build matrix
- PR number
