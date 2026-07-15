Claude Code Handover — G3 gate report preservation (2 sessions, 2 repos)

Background: PR #32's gate run report (report-detail.json) was never committed and is
gone from disk. noema-gate stamp writes eval_report_sha256 into the manifest —
a hash pointing at a lost file is a dangling audit reference. Reports must be durable
BEFORE the first production stamp.


SESSION E1 — spec amendment (rag-fish/RAGfish, direct commit to main)

Guard (FIRST): git remote get-url origin must contain rag-fish/RAGfish; else STOP.
git fetch && git pull; clean tree required.

Edit docs/noema/specs/spec-g3-promotion-gate.md — add a section
"## Report preservation (amended 2026-07-14)":


noema-gate run writes its report to a standard tracked location by default:
reports/g3/<pack_id>/<UTC-timestamp>-report.json. --out may override;
existing files are never silently overwritten (refuse, no --force for run).
noema-gate stamp refuses if the report file is not tracked by git in the
repository containing it (dangling-evidence prevention). Escape hatch
--allow-untracked-report exists but emits a distinct audit event recording
the override.
The gate.run audit event's outputs.sha256_refs MUST include the report hash.


Also fix nothing else. Single commit:
docs(specs): G3 report preservation amendment (dangling eval_report_sha256 prevention).
Archive prompt per convention. Report the new file sha256.

---

## Session execution notes

- Guard passed: `origin` is `https://github.com/rag-fish/RAGfish.git`.
- Working tree was clean; `git fetch && git pull` reported already up to date.
- Section inserted into `docs/noema/specs/spec-g3-promotion-gate.md` immediately
  before `## Non-goals (v0.8)`, verbatim as specified above.
- Archived per the `docs/prompts/` convention established in
  `2026-07-03-v0.8-ragfish-session.md` (this repo otherwise keeps prompts out of
  tree per `docs/development-prompts.md`; same override applies here).
- No other content in the spec file was touched.
