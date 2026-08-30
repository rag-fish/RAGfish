# `investigation_result` v0.1 contract

Status: Proposed

Issue: [rag-fish/RAGfish#34](https://github.com/rag-fish/RAGfish/issues/34)

Schema: [`investigation-result.schema.json`](investigation-result.schema.json)

## Purpose and boundary

`investigation_result` is the sole NOESIS → NOEMA handoff. It is an immutable snapshot of
NOESIS-calibrated advisory findings sufficient for presentation. It contains no raw evidence,
evidence-store handle, retrieval binding, credential, external endpoint, acquisition request, or
mutable investigation-state handle.

NOESIS assesses; human noesis governs. NOEMA may reorder, summarize, explain, and format only
what this handoff contains. The epistemic NOEMA layer remains distinct from the `noema-agent`
service.

## Semantic model

The schema deliberately keeps these concepts separate:

- `claims`: stable factual propositions; `claim_id` is minted by NOESIS.
- `assessments`: one bounded state per claim: `supported`, `partially_supported`,
  `contradicted`, `unresolved`, or `insufficient_evidence`. There is no binary truth field.
- `confidence`: NOESIS-calibrated confidence in an assessment. It uses the ordinal bands `low`,
  `moderate`, and `high`, plus a calibration basis. This avoids implying numeric precision.
  Confidence is not source trust.
- `uncertainties`: explicit residual uncertainty and its drivers, independent of assessment and
  confidence.
- `evidence_chain_summaries`: counts and relationship summaries only. A reported source count is
  not an independent-chain count; independence may be unknown. Artifact IDs provide audit
  linkage without exposing evidence content or evidence-store capability.
- `competing_hypotheses`: alternative explanations retained where the evidence does not force a
  single explanation.
- `recommendations`: advisory actions linked to existing claims and, where applicable, approval
  references. A recommendation is not a governance decision.
- `human_approval_references`: minimal, scoped, traceable references whose owner is structurally
  human-only. This is not the full Human Gate acquisition-record schema.
- `human_judgment_references`: independent human judgment, including disagreement. Such judgment
  does not edit NOESIS assessment or confidence.
- `approved_noesis_state`, `version_pins`, and `trace_references`: the frozen source-state,
  model/embedder/manifest pins required by G2, and audit artifacts needed to reconstruct the
  handoff without embedding raw evidence.

All top-level collections are present, even when optional-in-context collections are empty. This
makes absence explicit and keeps the handoff shape stable.

## Enforcement boundary

### Schema-enforceable

- the contract version, required fields, identifier shapes, timestamp shapes, and SHA-256 shapes;
- closed objects: undeclared fields such as `verified`, `raw_evidence`, credentials, endpoints,
  or store handles are rejected;
- the bounded assessment, confidence, uncertainty, independence, hypothesis, approval-outcome,
  and human-judgment vocabularies;
- human approval ownership has `identity_type: human`; AI/model/service ownership is
  unrepresentable;
- confidence is a calibrated ordinal object, not an arbitrary number or string;
- independent-chain count is `null` exactly when independence is `unknown`;
- local uniqueness within arrays of scalar references through `uniqueItems`.

### Validator-enforceable

JSON Schema cannot express every cross-collection or before/after invariant. A deterministic
handoff/presentation validator MUST enforce:

1. Every claim ID is unique and every claim-scoped collection contains exactly one entry for each
   claim. Every claim reference in hypotheses, recommendations, and human judgments resolves to
   that same claim set.
2. NOEMA output claim IDs are a subset of the handoff claim IDs, and the statement for each
   referenced ID is byte-for-byte identical to its handoff statement. Unknown IDs and silent
   statement replacement are rejected.
3. NOEMA carries each confidence object through unchanged. Equality is the v0.1 presentation
   rule and therefore satisfies `NOEMA confidence <= NOESIS confidence` without permitting
   arbitrary rewriting.
4. NOEMA carries assessments and uncertainties through unchanged. Human disagreement is stored
   only as an independent human-judgment reference and never mutates either value.
5. IDs in `approval_reference_ids` resolve to `human_approval_references`; approval scope and the
   referenced downstream action match. The full Human Gate validator owns acquisition-specific
   scope semantics.
6. For assessed or partially assessed independence, relationship counts sum to
   `independent_evidence_chain_count`; that count cannot exceed `reported_source_count`.
7. Claim, hypothesis, recommendation, approval-reference, and human-judgment-reference IDs are
   unique in their respective collections.
8. `approved_noesis_state.sha256` matches the canonical frozen NOESIS assessment artifact and the
   referenced trace/audit chain.

The consumer MUST treat the payload as read-only. Runtime isolation, credential removal, endpoint
removal, and evidence-store binding removal remain architectural controls outside JSON Schema.

## Examples and validation

- [`examples/valid-investigation-result.json`](examples/valid-investigation-result.json) passes.
- Files under [`examples/invalid/`](examples/invalid/) each violate one named rule. Five are
  rejected by the schema. `duplicate-claim-id.json` is intentionally schema-valid and is rejected
  by validator invariant 1; this demonstrates the boundary honestly rather than pretending JSON
  Schema can enforce key uniqueness across objects.

Validate syntax and examples with any JSON Schema Draft 2020-12 implementation that checks
`date-time` format. The choice of validator is tooling, not part of this architecture contract.

## Architectural alignment

This contract implements ADR-0004 I5/I6/I8, Governance Contract §6/§8, Capability Matrix rows
1–13, and Roadmap v3 Phase 0 #34. It preserves trust ≠ confidence, recompute-not-patch semantics,
human-only approval ownership, and the one-directional `investigation_result` boundary.

## Change policy

Backward-incompatible changes require a new contract version and architecture review. Additive
changes require review because closed objects intentionally reject undeclared fields.
