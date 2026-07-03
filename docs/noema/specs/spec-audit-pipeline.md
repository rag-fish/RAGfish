# Spec: Audit Pipeline (v0.8) — Event Schema, Hash Chain, Evidence Package

**Storage policy (decided 2026-07-02):** on-device / local by default. Export is explicit, optional, cryptographically verifiable, privacy-preserving. Cloud storage is never required.

## 1. Audit event schema (JSONL, append-only)

One canonical schema for both emitters (Python pipeline now, Swift runtime in v0.9).

```json
{
  "event_id": "uuid",
  "ts": "2026-07-02T10:00:00+09:00",
  "plane": "knowledge | runtime | policy",
  "actor": "noema-gate | pipeline-build | app | human:<id>",
  "action": "pack.build | gate.run | gate.stamp | pack.promote | policy.change | query.retrieve | query.generate",
  "triplet": {
    "embedder_id": "nomic-embed-text-v1.5",
    "model_id": "…",
    "manifest_sha256": "…"
  },
  "inputs": { "sha256_refs": ["…"] },
  "outputs": { "sha256_refs": ["…"] },
  "detail": { },
  "prev_hash": "…64 hex…",
  "event_hash": "…64 hex…"
}
```

Rules:
- **No raw content ever appears in an event.** Queries, chunks, and answers are referenced by sha256 only (`sha256_refs`). `detail` carries scalars (scores, counts, thresholds), never text bodies.
- `triplet` is mandatory for `query.*` and `gate.*` actions (G2), optional elsewhere.
- Runtime events (`query.retrieve`, `query.generate`) are **defined now, emitted from v0.9** — schema freeze here prevents a v0.9 migration.

## 2. Hash chain (tamper evidence)

- `event_hash = SHA-256( JCS(event with event_hash=null) )` where JCS = RFC 8785 canonical JSON.
- `prev_hash` = previous event's `event_hash`; genesis uses 64 zeros.
- Log file: `audit-<scope>.jsonl`, strictly append-only. One chain per scope (pipeline workspace; per-device in v0.9).
- **Cross-language risk:** Python and Swift must produce identical JCS bytes. Deliverable includes `audit/conformance/vectors.json` — ≥10 fixed events with expected hashes; both implementations must pass. This is a hard requirement, not a nice-to-have (number normalization and Unicode escaping are the usual failure points; mitigate by forbidding non-integer numbers in events — scores are emitted as strings, e.g. `"0.87"`).

`noema-audit verify <log.jsonl>` recomputes the chain; exit 0 iff intact. G6 check: `noema-audit coverage --log <log> --expect <actions>` fails if a governed action lacks an event.

## 3. Evidence package (export)

```
noema-evidence export --log <log.jsonl> --from <ts> --to <ts> \
  --pack <pack_dir>... --key <ed25519_private> [--include-queries]
```

Produces `evidence-<date>.tar.gz`:

```
package.json          # scope, time range, tool versions, policy_sha256
events.jsonl          # chain slice + anchor: hash of the event preceding the slice
manifests/*.json      # referenced RAGpack manifests
reports/*.json        # G3 eval reports
chain-check.json      # recomputed head hash at export time
SIGNATURE             # Ed25519 detached signature over sha256 of the tar payload (signature file excluded)
PUBKEY                # base64 public key (distribution of trust anchor is out-of-band)
```

Privacy defaults:
- Content-free: hashes and metadata only. `--include-queries` is an explicit opt-in and is itself recorded as a `policy.change`-class audit event.
- Verification is fully offline: `noema-evidence verify <pkg> --pubkey <key>` checks signature + chain slice + manifest hashes.

Crypto choices: Ed25519 (Python: `cryptography`; Swift v0.9: CryptoKit `Curve25519.Signing`). No platform attestation in v0.8 (see ADR-0012 trade-offs).

## 4. Threat model (scope-honest)

| Threat | Covered? |
|---|---|
| Post-hoc tampering of exported evidence | Yes (signature + chain) |
| Tampering of local log by an attacker who can also re-sign (key on same device) | **No** — local chain is tamper-*evident* against accidental/naive modification, not against a device-root adversary. State this plainly in consulting materials. |
| Omission of events (never written) | Partially — G6 coverage check catches missing events for known governed actions only. |
| Replay of an old evidence package as current | Mitigated by time range + anchor hash in `package.json`; verifier must check freshness contextually. |

## 5. Deliverables in pipeline PR (prompt B)

- `noema_audit/` module: emitter, JCS canonicalizer, chain verifier, coverage checker
- `noema_evidence/` module: exporter, verifier
- `audit/conformance/vectors.json` + tests
- Integration: `noema-gate` and pack build emit events through the emitter
- Tests: chain break detection, signature verification, redaction (assert no content strings leak into events), conformance vectors
